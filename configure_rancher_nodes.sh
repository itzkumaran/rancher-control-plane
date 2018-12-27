#!/bin/bash
sudo apt-get update
sudo apt-get install snapd
sudo snap install docker --classic
sudo snap start docker
sudo snap install helm --classic
