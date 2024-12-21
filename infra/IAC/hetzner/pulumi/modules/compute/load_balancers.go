package compute

import (
	"github.com/pulumi/pulumi-hetzner/sdk/go/hetzner"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

func CreateLoadBalancer(ctx *pulumi.Context) (*hetzner.LoadBalancer, error) {
	return hetzner.NewLoadBalancer(ctx, "loadbalancer", &hetzner.LoadBalancerArgs{
		Location: pulumi.String("fsn1"),
		Type:     pulumi.String("lb11"),
	})
}
