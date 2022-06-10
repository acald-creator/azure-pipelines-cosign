package main

import (
	"context"
	"fmt"
	"log"
	"os"

	"github.com/Azure/azure-sdk-for-go/sdk/storage/azblob"
)

func main() {
	accountName, ok := os.LookupEnv("AZURE_STORAGE_ACCOUNT_NAME")
	if !ok {
		panic("AZURE_STORAGE_ACCOUNT_NAME could not be found")
	}

	accountKey, ok := os.LookupEnv("AZURE_STORAGE_PRIMARY_ACCOUNT_KEY")
	if !ok {
		panic("AZURE_STORAGE_PRIMARY_ACCOUNT_KEY could not be found")
	}

	fmt.Printf("Azure Blob Storage\n")

	credential, err := azblob.NewSharedKeyCredential(accountName, accountKey)
	if err != nil {
		log.Fatal("Invalid credentials with error: " + err.Error())
	}

	serviceClient, err := azblob.NewServiceClientWithSharedKey(fmt.Sprintf("https://%s.blob.core.windows.net/", accountName), credential, nil)
	if err != nil {
		log.Fatal(err)
	}

	containerClient, err := serviceClient.NewContainerClient("tfstate")
	if err != nil {
		log.Fatal(err)
	}

	_, err = containerClient.Create(context.TODO(), nil)
	if err != nil {
		log.Fatal(err)
	}

	_, err = containerClient.Delete(context.TODO(), nil)
	if err != nil {
		log.Fatal(err)
	}
}
