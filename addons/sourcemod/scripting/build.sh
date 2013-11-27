#!/bin/bash
../../../../../scripting/spcomp rn-spectate.sp || (echo Failed && exit )
mv rn-spectate.smx ../plugins
