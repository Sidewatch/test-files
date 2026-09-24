// Jsonnet: a deployment template instantiated per environment.
local base = import 'base.libsonnet';

local service(name, replicas, env) = {
  apiVersion: 'apps/v1',
  kind: 'Deployment',
  metadata: { name: name, labels: { app: name, env: env } },
  spec: {
    replicas: replicas,
    template: {
      spec: {
        containers: [{
          name: name,
          image: 'registry.example.com/%s:%s' % [name, base.version],
          env: [{ name: k, value: std.toString(base.env[env][k]) } for k in std.objectFields(base.env[env])],
          resources: if env == 'prod' then { limits: { memory: '1Gi' } } else {},
        }],
      },
    },
  },
};

{
  ['%s-%s' % [name, env]]: service(name, if env == 'prod' then 4 else 1, env)
  for name in ['api', 'worker']
  for env in ['staging', 'prod']
}
