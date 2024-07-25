#!/bin/bash

# Enter source directory
cd $( dirname $0 )

set -x

mv pbincli eepastecli
sed -i 's/pbincli/eepastecli/g' $( grep -rl pbincli eepastecli )
sed -i 's/PBinCLI/EePasteCLI/g' $( grep -rl PBinCLI eepastecli )
sed -i 's/paste.i2pd.xyz/paste.easter-eggs.com/g' $( grep -rl paste.i2pd.xyz eepastecli )
