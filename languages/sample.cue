// CUE: a service schema and two concrete deployments that must satisfy it.
package deploy

#Service: {
	name:     string & =~"^[a-z][a-z0-9-]*$"
	replicas: int & >=1 & <=20 | *2
	image:    string
	ports: [...int & >0 & <65536]
	env: [string]: string
	resources: {
		cpu:    string | *"250m"
		memory: string | *"256Mi"
	}
}

services: [Name=_]: #Service & {name: Name}

services: {
	api: {
		image: "registry.example.com/api:1.4.0"
		replicas: 4
		ports: [8080, 9090]
		env: LOG_LEVEL: "info"
	}
	worker: {
		image: "registry.example.com/worker:1.4.0"
		ports: []
		resources: memory: "1Gi"
	}
}
