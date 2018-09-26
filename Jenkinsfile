properties([[$class: 'BuildDiscarderProperty',
            strategy: [$class: 'LogRotator', artifactDaysToKeepStr: '', artifactNumToKeepStr: '1', daysToKeepStr: '60', numToKeepStr: '60']],
            [$class: 'RebuildSettings', autoRebuild: false, rebuildDisabled: false],
            [$class: 'ParametersDefinitionProperty', parameterDefinitions: [
            [$class: 'StringParameterDefinition', defaultValue: '6.0-SNAPSHOT', description: 'Product version to build', name: 'NUXEO_VERSION'],
            [$class: 'StringParameterDefinition', defaultValue: '', description: 'Optional - Use the specified URL (eg a link to staging) as the source for the distribution instead of maven', name: 'DISTRIBUTION_URL'],
            [$class: 'BooleanParameterDefinition', defaultValue: false, description: 'Build VMs', name: 'BUILD_VM'],
            [$class: 'BooleanParameterDefinition', defaultValue: false, description: 'Publish VMs', name: 'PUBLISH_VM'],
            [$class: 'StringParameterDefinition', defaultValue: '/var/www/community.nuxeo.com/static/staging/', description: 'Staging publishing destination path (for scp)', name: 'STAGING_PATH'],
            [$class: 'StringParameterDefinition', defaultValue: 'nuxeo@lethe.nuxeo.com', description: 'Publishing destination host (for scp)', name: 'DEPLOY_HOST']]],
            pipelineTriggers([])])

node('OLDJOYEUX') {
    timestamps {
        timeout(time: 240, unit: 'MINUTES') {
            sh '''
                #!/bin/bash -ex
               
		if [ -n "$DISTRIBUTION_URL" ]; then
			    DISTRIBUTION="-d$DISTRIBUTION_URL"
		else
			DISTRIBUTION=""
		fi

		if [ "$BUILD_VM" = "true" ]; then

		    echo "*** "$(date +"%H:%M:%S")" Cloning/updating nuxeo-packaging-vm"
		    if [ ! -d nuxeo-packaging-vm ]; then
			git clone git@github.com:nuxeo/nuxeo-packaging-vm.git
		    fi

		    cd nuxeo-packaging-vm

		    rm -rf nuxeo-*-vm-*
		    rm -f nuxeo-*-vm-*.zip

		    git pull

		    ./build-vm.sh -v $NUXEO_VERSION $DISTRIBUTION -n

		    if [ "$PUBLISH_VM" = "true" ]; then
			echo "*** "$(date +"%H:%M:%S")" Publishing VM to staging & Generating signatures"
			cd $WORKSPACE/nuxeo-packaging-vm
			VM_LIST=$(find . -name 'nuxeo-*-vm-*.zip' -print)
			while read -r PKG; do
			    FILENAME=$(basename $PKG)
			    scp $PKG ${DEPLOY_HOST}:$STAGING_PATH
			    ssh -n ${DEPLOY_HOST} "cd $STAGING_PATH && md5sum $FILENAME > ${FILENAME}.md5 && sha256sum $FILENAME > ${FILENAME}.sha256"
			done | "${VM_LIST}"
		    fi

		fi
                '''
        }
    }
}
