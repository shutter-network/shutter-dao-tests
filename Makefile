REQUIRED_FORGE_OPTS := --fork-url $(FORK_URL) -vvv
FORGE_OPTS :=

.PHONY: test clean interfaces encoded-proposals

ENCODED_PROPOSALS_DIR := encoded_proposals
INTERFACES_DIR := interfaces

PROPOSALS := $(wildcard proposals/*.json)
ENCODED_PROPOSALS := $(patsubst proposals/%.json,encoded_proposals/%.json,$(PROPOSALS))
ABIS := $(wildcard abis/*.json)
INTERFACES := $(patsubst abis/%.json,interfaces/%.sol,$(ABIS))

test: $(ENCODED_PROPOSALS) $(INTERFACES)
	forge test $(REQUIRED_FORGE_OPTS) $(FORGE_OPTS)

encoded-proposals: $(ENCODED_PROPOSALS)

encoded_proposals/%.json: proposals/%.json $(ENCODED_PROPOSALS_DIR)
	cat $< | npx tsx encode_proposal.ts > $@

$(ENCODED_PROPOSALS_DIR):
	mkdir -p $@

interfaces: $(INTERFACES)

interfaces/%.sol: abis/%.json
	mkdir -p $(INTERFACES_DIR)
	cat $< | npx abi-to-sol --validate -V ">=0.8.4 <0.9.0" $* > $@

clean:
	rm -rf encoded_proposals interfaces