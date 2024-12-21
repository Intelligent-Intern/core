package storage

import (
	"github.com/pulumi/pulumi-hetzner/sdk/go/hetzner"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

func CreateS3Bucket(ctx *pulumi.Context) (*hetzner.S3Bucket, error) {
	return hetzner.NewS3Bucket(ctx, "s3-bucket", &hetzner.S3BucketArgs{
		Region: pulumi.String("fsn1"),
	})
}
