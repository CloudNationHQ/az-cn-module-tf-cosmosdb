.PHONY: test test_extended

export TF_PATH

test:
	cd tests && go test -v -timeout 60m -run TestApplyNoError/$(TF_PATH) ./mongodb_test.go

test_extended:
	cd tests && env go test -v -timeout 60m -run TestCosmosDbAccount ./mongodb_extended_test.go
