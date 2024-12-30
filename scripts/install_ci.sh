#!/bin/bash

mkdir -p ~/.local/share/nvim/site/pack/ci/opt
ln -s "$PWD" ~/.local/share/nvim/site/pack/ci/opt
cd ~/.local/share/nvim/site/pack/ci/opt
git clone --depth 1 https://github.com/nvim-lua/plenary.nvim 
git clone --depth 1 https://github.com/nvim-treesitter/nvim-treesitter.git 
