package main

import (
	"os"

	"github.com/nanoteck137/tunecopy"
	"github.com/spf13/cobra"
)

var rootCmd = &cobra.Command{
	Use:     tunecopy.AppName,
	Version: tunecopy.Version,
	CompletionOptions: cobra.CompletionOptions{
		DisableDefaultCmd: true,
	},
}

func init() {
	rootCmd.SetVersionTemplate(tunecopy.VersionTemplate(tunecopy.AppName))
}

func main() {
	err := rootCmd.Execute()
	if err != nil {
		os.Exit(1)
	}
}
