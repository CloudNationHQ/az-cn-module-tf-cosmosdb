package main

import (
	"context"
	"strings"
	"testing"

	"github.com/Azure/azure-sdk-for-go/sdk/azidentity"
	"github.com/Azure/azure-sdk-for-go/sdk/resourcemanager/cosmos/armcosmos"
	"github.com/cloudnationhq/az-cn-module-tf-cosmosdb/shared"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/require"
)

type CosmosDbAccountDetails struct {
	ResourceGroupName string
	AccountName       string
}

type ClientSetup struct {
	subscriptionId string
	cosmosClient   *armcosmos.DatabaseAccountsClient
}

func (details *CosmosDbAccountDetails) GetDatabaseAccount(t *testing.T,client *armcosmos.DatabaseAccountsClient,) *armcosmos.DatabaseAccountGetResults {
	resp, err := client.Get(context.Background(), details.ResourceGroupName, details.AccountName, nil)
	require.NoError(t, err, "Failed to get database account")
	return &resp.DatabaseAccountGetResults
}

func (setup *ClientSetup) InitializeCosmosDbAccountClient(t *testing.T, cred *azidentity.DefaultAzureCredential) {
	var err error
	setup.cosmosClient, err = armcosmos.NewDatabaseAccountsClient(setup.subscriptionId, cred, nil)
	require.NoError(t, err, "Failed to create cosmos client")
}

func TestCosmosDbAccount(t *testing.T) {
	t.Run("VerifyCosmosDbAccount", func(t *testing.T) {
		t.Parallel()

		cred, err := azidentity.NewDefaultAzureCredential(nil)
		require.NoError(t, err, "Failed to create credential")

		tfOpts := shared.GetTerraformOptions("../examples/complete")
		defer shared.Cleanup(t, tfOpts)
		terraform.InitAndApply(t, tfOpts)

		cosmosDbAccountMap := terraform.OutputMap(t, tfOpts, "account")
		subscriptionId := terraform.Output(t, tfOpts, "subscriptionId")

		cosmosDbAccountDetails := &CosmosDbAccountDetails{
			ResourceGroupName: cosmosDbAccountMap["resource_group_name"],
			AccountName:       cosmosDbAccountMap["name"],
		}

		ClientSetup := &ClientSetup{subscriptionId: subscriptionId}
		ClientSetup.InitializeCosmosDbAccountClient(t, cred)
		cosmosDbAccount := cosmosDbAccountDetails.GetDatabaseAccount(t, ClientSetup.cosmosClient)

		t.Run("VerifyCosmosDbAccount", func(t *testing.T) {
			verifyCosmosDbAccount(t, cosmosDbAccountDetails, cosmosDbAccount)
		})
	})
}

func verifyCosmosDbAccount(t *testing.T,details *CosmosDbAccountDetails,databaseAccount *armcosmos.DatabaseAccountGetResults,) {
	t.Helper()

	require.Equal(
		t,
		details.AccountName,
		*databaseAccount.Name,
		"Database account name does not match expected value",
	)

	require.Equal(
		t,
		"Succeeded",
		string(*databaseAccount.Properties.ProvisioningState),
		"Database account provisioning state is not Succeeded",
	)

	require.True(
		t,
	strings.HasPrefix(details.AccountName, "cosmos"),
		"Database account name does not start with the right abbreviation",
	)
}
