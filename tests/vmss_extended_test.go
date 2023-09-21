package main

import (
	"context"
	"testing"

	"github.com/Azure/azure-sdk-for-go/sdk/azidentity"
	"github.com/Azure/azure-sdk-for-go/sdk/resourcemanager/compute/armcompute"
	"github.com/cloudnationhq/az-cn-module-tf-vmss/shared"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/require"
)

type vmssDetails struct {
	ResourceGroupName string
	Name              string
	InstanceId        string
}

type ClientSetup struct {
	SubscriptionID string
	VmssClient     *armcompute.VirtualMachineScaleSetVMsClient
}

func (details *vmssDetails) GetVmss(t *testing.T,client *armcompute.VirtualMachineScaleSetVMsClient) *armcompute.VirtualMachineScaleSetVM {
	resp, err := client.Get(context.Background(), details.ResourceGroupName, details.Name, details.InstanceId, nil)
	require.NoError(t, err, "Failed to get VMSS")
	return &resp.VirtualMachineScaleSetVM
}

func (setup *ClientSetup) InitializeVmssClient(t *testing.T, cred *azidentity.DefaultAzureCredential) {
	var err error
	setup.VmssClient, err = armcompute.NewVirtualMachineScaleSetVMsClient(setup.SubscriptionID, cred, nil)
	require.NoError(t, err, "Failed to create VMSS client")
}

func TestVmss(t *testing.T) {
	t.Run("VerifyVmss", func(t *testing.T) {
		t.Parallel()

		cred, err := azidentity.NewDefaultAzureCredential(nil)
		require.NoError(t, err, "Failed to create credential")

		tfOpts := shared.GetTerraformOptions("../examples/complete")
		defer shared.Cleanup(t, tfOpts)
		terraform.InitAndApply(t, tfOpts)

		vmssMap := terraform.OutputMap(t, tfOpts, "vmss")
		subscriptionId := terraform.Output(t, tfOpts, "subscriptionId")

		vmssDetails := &vmssDetails{
			ResourceGroupName: vmssMap["resource_group_name"],
			Name:              vmssMap["name"],
		}

		clientSetup := &ClientSetup{SubscriptionID: subscriptionId}
		clientSetup.InitializeVmssClient(t, cred)
		vmss := vmssDetails.GetVmss(t, clientSetup.VmssClient)

		t.Run("VerifyVmss", func(t *testing.T) {
			verifyVmss(t, vmssDetails, vmss)
		})
	})
}

func verifyVmss(t *testing.T, details *vmssDetails, vmss *armcompute.VirtualMachineScaleSetVM) {

}
