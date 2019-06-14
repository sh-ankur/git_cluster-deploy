#!/bin/bash

# deploy tendermint on our cluster

LOCAL_DEPLOY_REPO_PATH=$HOME/tendermint
TENDERMINT_BUILD_DIR=$GOPATH/src/github.com/tendermint

# create required directories

rm -rf ${TENDERMINT_BUILD_DIR}
rm -rf ${LOCAL_DEPLOY_REPO_PATH}

mkdir -p ${TENDERMINT_BUILD_DIR}
mkdir -p ${LOCAL_DEPLOY_REPO_PATH}

cd ${LOCAL_DEPLOY_REPO_PATH}
git init --bare

# create the post-receive hook
cd hooks || exit

tee post-receive <<EOF
#!/bin/bash

export GOBIN=/var/nfs/gobin
export PATH=$PATH:$GOBIN

# tendermint build directory
TENDERMINT_BUILD_DIR=${TENDERMINT_BUILD_DIR}
LOCAL_DEPLOY_REPO_PATH=${LOCAL_DEPLOY_REPO_PATH}

cd \${TENDERMINT_BUILD_DIR}

unset GIT_DIR

# delete the existing directory
rm -rf tendermint
git clone ${LOCAL_DEPLOY_REPO_PATH}

# build tendermint
cd tendermint || exit

echo "waiting 5s before building tendermint"
./cluster.sh down

make get_tools && make get_vendor_deps
make && make install

# copy the config files to nfs
rm -rf /var/nfs/tendermint_config
cp -a tendermint_config /var/nfs/

# restart the tendermint cluster
./cluster.sh restart

EOF

# make the post-receive hook executable
chmod +x post-receive
