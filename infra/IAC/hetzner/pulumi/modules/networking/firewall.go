package networking

import (
	"github.com/pulumi/pulumi-hetzner/sdk/go/hetzner"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

func CreateFirewall(ctx *pulumi.Context) (*hetzner.Firewall, error) {
	return hetzner.NewFirewall(ctx, "firewall", &hetzner.FirewallArgs{
		Name: pulumi.String("server-firewall"),
	})
}
