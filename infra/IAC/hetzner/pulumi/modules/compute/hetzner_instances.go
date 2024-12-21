package compute

import (
	"github.com/pulumi/pulumi-hetzner/sdk/go/hetzner"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

func CreateHetznerServer(ctx *pulumi.Context, subdomain string) (*hetzner.Server, error) {
	return hetzner.NewServer(ctx, subdomain+"-server", &hetzner.ServerArgs{
		ServerType: pulumi.String("cpx21"),
		Image:      pulumi.String("docker-ce"),
		Location:   pulumi.String("fsn1"),
	})
}
