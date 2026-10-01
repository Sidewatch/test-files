// Bicep 0.3x (current stable, extensions and .bicepparam syntax) — syntax showcase
// Warehouse platform: storage, app service, key vault and a deployment script.
/* A block comment
   spanning lines. TODO: split into modules. */

// ── Scope and metadata ──────────────────────────────────────────────
targetScope = 'resourceGroup'

metadata description = 'Warehouse platform infrastructure'
metadata author = 'Platform team'

// ── Imports and extensions ──────────────────────────────────────────
import { sharedTags, regionCode } from './shared.bicep'
import * as constants from './constants.bicep'
using './main.bicep'

// ── Decorators and parameters ───────────────────────────────────────
@description('Deployment environment')
@allowed([
  'dev'
  'staging'
  'prod'
])
param environment string = 'dev'

@minLength(3)
@maxLength(11)
param prefix string = 'acme'

@minValue(1)
@maxValue(100)
param instanceCount int = 2

@secure()
param adminPassword string

@description('Feature flags')
param enableDiagnostics bool = true

param location string = resourceGroup().location
param tags object = {
  environment: environment
  owner: 'warehouse-team'
  'cost-center': '1234'
}
param subnets array = [
  { name: 'web', prefix: '10.0.1.0/24' }
  { name: 'data', prefix: '10.0.2.0/24' }
]
param nullableValue string?
param config {
  name: string
  size: int
  optional: bool?
} = {
  name: 'default'
  size: 3
}

// ── Types ───────────────────────────────────────────────────────────
@export()
type skuName = 'Standard_LRS' | 'Standard_GRS' | 'Premium_LRS'

type stockItem = {
  sku: string
  @minValue(0)
  qty: int
  tags: string[]
  notes: string?
  *: string
}

type fixedTuple = [string, int, bool]

// ── Variables ───────────────────────────────────────────────────────
var storageName = toLower('st${prefix}${environment}${uniqueString(resourceGroup().id)}')
var isProd = environment == 'prod'
var sku = isProd ? 'Standard_GRS' : 'Standard_LRS'
var allTags = union(tags, sharedTags, { deployed: 'bicep' })
var multiline = '''
Multi-line string
with 'quotes' and ${not interpolated}
'''
var escapes = 'tab\there, newline\nhere, quote \' backslash \\ unicode \u{1F600} dollar \${x}'
var numbers = {
  int: 42
  negative: -7
  big: 9223372036854775807
  hex: 0x2A
}
var floatLike = json('1.5')
var nested = {
  level1: {
    level2: [
      1
      2
      3
    ]
  }
}
var names = [for i in range(0, instanceCount): 'vm-${i}']
var filtered = filter(subnets, s => s.name != 'data')
var mapped = map(subnets, (s, i) => '${i}-${s.name}')
var sorted = sort(names, (a, b) => a < b)
var total = reduce([1, 2, 3], 0, (acc, cur) => acc + cur)
var safeAccess = config.?optional ?? false
var indexed = subnets[0].name
var dynamicProp = nested['level1'].level2[0]
var comparisons = (1 < 2) && (2 <= 3) || !(3 > 4) && (4 >= 4) && (5 != 6) && (7 =~ 7) && ('a' !~ 'b')
var arithmetic = (1 + 2) * 3 - 4 / 2 % 3
var coalesced = nullableValue ?? 'fallback'
var nonNull = nullableValue!
var spreadObj = { ...tags, extra: 'yes' }
var spreadArr = [...names, 'extra']

// ── Existing resources ──────────────────────────────────────────────
resource existingVnet 'Microsoft.Network/virtualNetworks@2023-05-01' existing = {
  name: 'shared-vnet'
  scope: resourceGroup('shared-rg')
}

// ── Resources ───────────────────────────────────────────────────────
resource storage 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageName
  location: location
  tags: allTags
  sku: {
    name: sku
  }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    supportsHttpsTrafficOnly: true
    networkAcls: {
      defaultAction: 'Deny'
      ipRules: [for ip in ['192.0.2.1', '192.0.2.2']: {
        value: ip
        action: 'Allow'
      }]
    }
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' = {
  parent: storage
  name: 'default'
}

resource container 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  parent: blobService
  name: 'uploads'
  properties: {
    publicAccess: 'None'
  }
}

resource plan 'Microsoft.Web/serverfarms@2022-09-01' = if (instanceCount > 0) {
  name: '${prefix}-plan'
  location: location
  sku: {
    name: isProd ? 'P1v3' : 'B1'
    capacity: instanceCount
  }
}

resource sites 'Microsoft.Web/sites@2022-09-01' = [for (name, i) in names: if (i < 3) {
  name: '${prefix}-site-${name}'
  location: location
  dependsOn: [
    plan
  ]
  properties: {
    serverFarmId: plan.id
    siteConfig: {
      appSettings: [
        {
          name: 'STORAGE_CONNECTION'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storage.name};EndpointSuffix=${environment().suffixes.storage}'
        }
        {
          name: 'ADMIN_PASSWORD'
          value: adminPassword
        }
      ]
    }
  }
}]

resource diag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (enableDiagnostics) {
  name: 'diag'
  scope: storage
  properties: {
    metrics: [
      {
        category: 'Transaction'
        enabled: true
      }
    ]
  }
}

resource vault 'Microsoft.KeyVault/vaults@2023-02-01' = {
  name: '${prefix}-kv'
  location: location
  properties: {
    tenantId: subscription().tenantId
    sku: { family: 'A', name: 'standard' }
    accessPolicies: []
  }
}

// ── Modules ─────────────────────────────────────────────────────────
module network './modules/network.bicep' = {
  name: 'networkDeploy'
  scope: resourceGroup('network-rg')
  params: {
    location: location
    subnets: subnets
  }
}

module registryModule 'br/public:avm/res/container-registry/registry:0.1.0' = {
  name: 'registry'
  params: {
    name: '${prefix}acr'
  }
}

module loopedModules './modules/worker.bicep' = [for i in range(0, 2): {
  name: 'worker-${i}'
  params: {
    index: i
  }
}]

// ── User-defined functions ──────────────────────────────────────────
func buildName(prefix string, suffix string) string => '${prefix}-${suffix}'

@export()
func double(n int) int => n * 2

// ── Outputs ─────────────────────────────────────────────────────────
output blobEndpoint string = storage.properties.primaryEndpoints.blob
output storageId string = storage.id
output siteNames array = [for (name, i) in names: sites[i].name]
output isProduction bool = isProd
output summary object = {
  name: storage.name
  tags: allTags
}
output secretUri string = vault.properties.vaultUri

// ── Further constructs ──────────────────────────────────────────────
targetScope = 'subscription'
targetScope = 'managementGroup'
targetScope = 'tenant'

param secretValue string = newGuid()
param objectParam object = {}
param nestedDefaults {
  retries: int
  mode: 'fast' | 'safe'
  tags: { *: string }
  list: (string | int)[]
  tuple: [string, int]
  nullable: string?
} = {
  retries: 3
  mode: 'safe'
  tags: {}
  list: ['a', 1]
  tuple: ['x', 1]
}

@sys.description('Qualified decorator')
@sys.metadata({ owner: 'platform', purpose: 'demo' })
@discriminator('kind')
type shape = circle | square
type circle = { kind: 'circle', radius: int }
type square = { kind: 'square', side: int }
type resourceRef = resource
type fromResource = resourceInput<'Microsoft.Storage/storageAccounts@2023-01-01'>
type outputOf = resourceOutput<'Microsoft.Storage/storageAccounts@2023-01-01'>
type derived = typeof(allTags)
type unionOfLiterals = 1 | 2 | 3 | true | 'text' | null
type strArray = string[][]
type readonlyish = {
  @minLength(1)
  @maxLength(64)
  name: string
  @secure()
  password: string
  optionalField: int?
}

// Operators and expression forms
var ops = {
  add: 1 + 2
  sub: 3 - 1
  mul: 2 * 3
  div: 8 / 2
  mod: 9 % 4
  and: true && false
  or: true || false
  not: !true
  eq: 1 == 1
  neq: 1 != 2
  gt: 2 > 1
  gte: 2 >= 2
  lt: 1 < 2
  lte: 1 <= 1
  eqi: 'A' =~ 'a'
  neqi: 'A' !~ 'b'
  coalesce: null ?? 'x'
  ternary: true ? 'yes' : 'no'
  unary: -(1 + 2)
  nonNull: nullableValue!
  safeProp: config.?name
  safeIdx: subnets[?0]
  dynamicIdx: config['name']
  nestedArr: [[1, 2], [3, 4]][1][0]
  lambdaCall: map([1, 2, 3], x => x * 2)
  multiLambda: reduce([1, 2], 0, (acc, x) => acc + x)
  indexedLambda: map(range(0, 3), (i) => i * i)
  inString: 'value is ${1 + 2} and ${ops.add}'
  nestedInterp: 'a ${'b ${'c'}'}'
  literalDollar: '\${notInterpolated}'
  hexEscape: '\u{41}'
  quoted: 'single \'quote\''
  newline: 'line1\nline2\r\ttab'
}

var jsonLiteral = json('{"key": [1, 2, {"nested": null}]}')
var loadedText = loadTextContent('./template.txt')
var loadedJson = loadJsonContent('./data.json', '$.items')
var loadedYaml = loadYamlContent('./data.yaml')
var loadedBase64 = loadFileAsBase64('./image.png')
var fileHash = base64(loadTextContent('./a.txt'))
var secure = sys.concat('a', 'b')
var stringFns = {
  upper: toUpper('abc')
  lower: toLower('ABC')
  trimmed: trim('  x ')
  sub: substring('hello', 1, 3)
  repl: replace('a-b', '-', '_')
  split: split('a,b', ',')
  join: join(['a', 'b'], ',')
  fmt: format('{0}-{1}', 'a', 'b')
  idx: indexOf('abc', 'b')
  starts: startsWith('abc', 'a')
  contains: contains('abc', 'b')
  empty: empty('')
  len: length('abc')
  uri: uri('https://example.com', 'path')
  encode: uriComponent('a b')
  b64: base64ToString(base64('x'))
  guid: guid(subscription().id, 'seed')
  uniq: uniqueString(resourceGroup().id, 'seed')
  padded: padLeft('7', 3, '0')
  dateAdd: dateTimeAdd(utcNow(), 'P1D')
  epoch: dateTimeToEpoch(utcNow('u'))
  tickMark: tickMark
}
var tickMark = utcNow('yyyy-MM-dd')
var arrayFns = {
  first: first([1, 2])
  last: last([1, 2])
  concat: concat([1], [2])
  take: take([1, 2, 3], 2)
  skip: skip([1, 2, 3], 1)
  flatten: flatten([[1], [2]])
  zip: items({ a: 1 })
  keys: keys({ a: 1 })
  union: union({ a: 1 }, { b: 2 })
  intersection: intersection([1, 2], [2, 3])
  mapValues: mapValues({ a: 1 }, v => v + 1)
  toObject: toObject([{ k: 'a' }], e => e.k)
  groupBy: groupBy([{ k: 'a' }], e => e.k)
  any: any(1)
  min: min(1, 2)
  max: max([1, 2])
  sum: sum
  int: int('42')
  bool: bool('true')
  string: string(42)
  array: array('x')
  cidr: cidrSubnet('10.0.0.0/16', 24, 1)
  range: range(1, 3)
  tryGet: tryGet({ a: 1 }, 'a')
}
var sum = 0

// Resources of every shape
resource scoped 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, 'role')
  scope: storage
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'role-definition-id')
    principalId: 'principal-id-placeholder'
    principalType: 'ServicePrincipal'
  }
}

resource childInline 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: 'other'
  scope: resourceGroup('other-rg')
  resource blob 'blobServices' existing = {
    name: 'default'
  }
}

resource ifElse 'Microsoft.Resources/deploymentScripts@2023-08-01' = if (isProd && !empty(location)) {
  name: 'script'
  location: location
  kind: 'AzureCLI'
  properties: {
    azCliVersion: '2.50.0'
    retentionInterval: 'P1D'
    scriptContent: '''
      echo "hello"
      az group list --query "[].name" -o tsv
    '''
    environmentVariables: [
      { name: 'SECRET', secureValue: adminPassword }
    ]
  }
  #disable-next-line no-unused-existing-resources
  dependsOn: [ storage, vault ]
}

#disable-next-line no-hardcoded-env-urls
var hardcoded = 'https://management.azure.com/'

@batchSize(2)
resource batched 'Microsoft.Network/networkInterfaces@2023-05-01' = [for i in range(0, 4): {
  name: 'nic-${i}'
  location: location
  properties: {}
}]

resource nestedLoops 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: 'vnet'
  location: location
  properties: {
    addressSpace: { addressPrefixes: ['10.0.0.0/16'] }
    subnets: [for (subnet, index) in subnets: {
      name: subnet.name
      properties: {
        addressPrefix: subnet.prefix
        delegations: index == 0 ? [] : null
      }
    }]
  }
}

output conditionalOutput string = isProd ? vault.properties.vaultUri : ''
output secretOut string = adminPassword
@secure()
output securedOutput string = adminPassword
@description('Described output')
output typedOutput resourceInfo = {
  id: storage.id
}
output loopOutput array = [for sub in subnets: sub.name]
output filteredOutput array = filter(subnets, s => s.name == 'web')
// TODO: split modules into a registry.

// ── Extensions, assertions and newer decorators ─────────────────────
// Extension declarations (replace the removed `provider` keyword)
extension az
extension kubernetes with {
  namespace: 'default'
  kubeConfig: adminPassword
} as k8s
extension 'br:mcr.microsoft.com/bicep/extensions/microsoftgraph/v1.0:0.1.8-preview' as graph

// Assertions evaluated at compile time
assert hasInstances = instanceCount > 0
assert validEnvironment = contains(['dev', 'staging', 'prod'], environment)

// More decorators
@onlyIfNotExists()
resource seededStorage 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: 'seed${uniqueString(resourceGroup().id)}'
  location: location
  sku: { name: 'Standard_LRS' }
  kind: 'StorageV2'
}

@sealed()
type strictObject = {
  id: string
  @minLength(1)
  label: string
}

@validate(x => x >= 0, 'Value must not be negative')
param nonNegative int = 0

@validate(v => startsWith(v, 'acme'), 'Must start with acme')
param prefixed string = 'acme-001'

@metadata({ category: 'network' })
@description('Imported-and-reexported type')
@export()
type endpoint = {
  host: string
  port: int
  scheme: 'http' | 'https'
}

@export()
var exportedVariable = 'shared value'

@export()
func triple(n int) int => n * 3

// Lambda-typed and generic-looking helpers
func applyTwice(value int, fn (int) => int) int => fn(fn(value))
func joinNames(names string[], separator string) string => join(names, separator)
func maybeUpper(input string?) string => input == null ? '' : toUpper(input)

// Typed outputs and resource-derived types
output endpointOut endpoint = {
  host: 'example.com'
  port: 443
  scheme: 'https'
}
output storageProps resourceOutput<'Microsoft.Storage/storageAccounts@2023-01-01'>.properties = storage.properties
param storageInput resourceInput<'Microsoft.Storage/storageAccounts@2023-01-01'>.properties = {}

// Imports of every form
import { endpoint as importedEndpoint, triple as importedTriple } from './types.bicep'
import * as everything from './everything.bicep'
import 'kubernetes@1.0.0' with { namespace: 'default', kubeConfig: 'config' } as kubeImport

// Safe-dereference, spread and nullable operators
var maybeName = config.?name ?? 'unnamed'
var maybeItem = subnets[?5].?name
var combined = { ...tags, ...{ extra: 'x' }, overridden: 'last' }
var spreadList = [...names, ...['more'], 'tail']
var nonNullAssert = nullableValue!
var nested2 = { a: { b: { c: 'deep' } } }
var deepSafe = nested2.?a.?b.?c
var typeCheck = typeof(nested2)

// Loops with filters, indexes and nested comprehensions
var evenNumbers = [for n in range(0, 10): if (n % 2 == 0) n]
var pairs = [for (item, idx) in names: { index: idx, name: item }]
var grid = [for row in range(0, 3): [for col in range(0, 3): row * 3 + col]]
var lookups = toObject(names, n => n, n => length(n))
var objectLoop = { for n in names: n: toUpper(n) }

// Resource and module features
resource withLock 'Microsoft.Authorization/locks@2020-05-01' = {
  scope: storage
  name: 'lock'
  properties: {
    level: 'CanNotDelete'
    notes: 'Prevent deletion'
  }
}

resource nestedChild 'Microsoft.Network/virtualNetworks@2023-05-01' existing = {
  name: 'shared-vnet'

  resource childSubnet 'subnets' existing = {
    name: 'default'
  }
}

module withExtensionConfig './modules/graph.bicep' = {
  name: 'graphDeploy'
  params: {
    displayName: 'Warehouse App'
  }
}

module conditionalModule './modules/optional.bicep' = if (isProd) {
  name: 'optional'
  params: {
    flag: true
  }
}

output childSubnetId string = nestedChild::childSubnet.id
output nestedAccess string = withLock.properties.level

// Linter directives
#disable-next-line no-unused-params use-secure-value-for-secure-inputs
param unusedParam string = ''

// ── .bicepparam file syntax (shown for highlighting) ────────────────
// using 'main.bicep'
// using none
// extends './base.bicepparam'
// param environment = 'prod'
// param adminPassword = readEnvironmentVariable('ADMIN_PASSWORD', 'example-not-a-real-key')
// param instanceCount = int(readEnvironmentVariable('INSTANCES', '3'))
// param secret = externalInput('sys.cli', 'az account show')
// var common = { owner: 'team' }
// param tags = common
