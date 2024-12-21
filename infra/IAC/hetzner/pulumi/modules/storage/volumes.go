package storage

import (
	"github.com/pulumi/pulumi-hetzner/sdk/go/hetzner"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

func CreateVolume(ctx *pulumi.Context) (*hetzner.Volume, error) {
	return hetzner.NewVolume(ctx, "volume", &hetzner.VolumeArgs{
		Size:     pulumi.Int(100),
		Location: pulumi.String("fsn1"),
	})
}
