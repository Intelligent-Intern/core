package main

import (
	"fmt"
	"github.com/pulumi/pulumi-hetzner/sdk/go/hetzner"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

func main() {
	pulumi.Run(func(ctx *pulumi.Context) error {
		// Define the list of services and subdomains
		services := map[string]string{
			"grafana":     "Grafana Monitoring",
			"prometheus":  "Prometheus Monitoring",
			"loki":        "Loki Logging",
			"fluentd":     "Fluentd Log Aggregator",
			"postgresql":  "PostgreSQL Database",
			"pgadmin":     "PgAdmin for PostgreSQL",
			"rabbitmq":    "RabbitMQ Message Broker",
			"redis":       "Redis Cache",
			"redis-commander": "Redis Commander UI",
			"vault":       "Vault Secret Management",
			"neo4j":       "Neo4j Graph Database",
			"symfony":     "Symfony API Backend",
		}

		// Automatically lookup the DNS Zone for the domain
		zone, err := hetzner.LookupDnsZone(ctx, &hetzner.LookupDnsZoneArgs{
			Name: pulumi.String("intelligent-intern.com"),
		})
		if err != nil {
			return fmt.Errorf("failed to find DNS zone: %w", err)
		}

		// Iterate over the services and create instances
		for subdomain, description := range services {
			// Create Hetzner server
			server, err := hetzner.NewServer(ctx, subdomain+"-server", &hetzner.ServerArgs{
				ServerType: pulumi.String("cpx21"),
				Image:      pulumi.String("docker-ce"),
				Location:   pulumi.String("fsn1"),
			})
			if err != nil {
				return fmt.Errorf("failed to create server for %s: %w", subdomain, err)
			}

			// Create DNS record for the service
			_, err = hetzner.NewDnsRecord(ctx, subdomain+"-dns", &hetzner.DnsRecordArgs{
				ZoneId: pulumi.String(zone.Id),
				Name:   pulumi.String(subdomain),
				Type:   pulumi.String("A"),
				Value:  server.Ipv4Address,
			})
			if err != nil {
				return fmt.Errorf("failed to create DNS record for %s: %w", subdomain, err)
			}

			ctx.Log.Info(fmt.Sprintf("Deployed %s at subdomain: %s.intelligent-intern.com", description, subdomain), nil)
		}

		return nil
	})
}
