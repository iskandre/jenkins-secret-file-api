#! /bin/sh
set -e

JENKINS_URL="http://localhost:8081"
JENKINS_USER=XXX
JENKINS_USER_PASS=XXX
FILE_PATH="/var/jenkins_home/secrets/myname-secrets/auth_file.txt"
SECRET_TEXT="https://www.google.com"

JENKINS_CRUMB=$(curl -u "$JENKINS_USER:$JENKINS_USER_PASS" -s --cookie-jar /tmp/cookies "$JENKINS_URL/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,\":\",//crumb)")
# example: Jenkins-Crumb:b37975b7b3f1c874413ca76d156487ae0dbb92129a4ada00fbf35268d28c54a7'
ACCESS_TOKEN=$(curl -u "$JENKINS_USER:$JENKINS_USER_PASS" -H "$JENKINS_CRUMB" -s \
                    --cookie /tmp/cookies "$JENKINS_URL/me/descriptorByName/jenkins.security.ApiTokenProperty/generateNewToken" \
                    --data 'newTokenName=GlobalToken' | jq -r '.data.tokenValue')
# example: {"status":"ok","data":{"tokenName":"GlobalToken","tokenUuid":"59922909-2f1b-4df2-848d-b5301eaeb38b","tokenValue":"11e280f6aa13c15c78f90af8a7e0be0329"}}# 


SECRET_ID="secret-file-$(cat /proc/sys/kernel/random/uuid)-api"
json="json={\"\": \"\", \"credentials\": {\"file\": \"file0\", \"id\": \"$SECRET_ID\", \"description\": \"secret-file created by API\", \"stapler-class\": \"org.jenkinsci.plugins.plaincredentials.impl.FileCredentialsImpl\", \"\$class\": \"org.jenkinsci.plugins.plaincredentials.impl.FileCredentialsImpl\"}}"
curl -X POST \
  $JENKINS_URL/credentials/store/system/domain/_/createCredentials  \
  -u "$JENKINS_USER:$ACCESS_TOKEN" \
  -H "$JENKINS_CRUMB" \
  -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9' \
  -H 'content-type: multipart/form-data;' \
  -F file0=@$FILE_PATH  \
  -F "$json"


JENKINS_CRUMB_STRIPPED=${JENKINS_CRUMB##*:}
SECRET_ID="secret-text-$(cat /proc/sys/kernel/random/uuid)-api"
ENCODED_SECRET_TEXT=$(printf %s $SECRET_TEXT|jq -sRr @uri)

curl -X POST \
$JENKINS_URL/credentials/store/system/domain/_/createCredentials \
  -u "$JENKINS_USER:$ACCESS_TOKEN" \
  -H "$JENKINS_CRUMB" \
  -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9' \
  -H 'content-type: application/x-www-form-urlencoded' \
-d "_.scope=GLOBAL&_.username=&_.password=&_.id=&_.description=&stapler-class=com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl&%24class=com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl&stapler-class=org.jenkinsci.plugins.github_branch_source.GitHubAppCredentials&%24class=org.jenkinsci.plugins.github_branch_source.GitHubAppCredentials&stapler-class=org.jenkinsci.plugin.gitea.credentials.PersonalAccessTokenImpl&%24class=org.jenkinsci.plugin.gitea.credentials.PersonalAccessTokenImpl&stapler-class=com.cloudbees.jenkins.plugins.sshcredentials.impl.BasicSSHUserPrivateKey&%24class=com.cloudbees.jenkins.plugins.sshcredentials.impl.BasicSSHUserPrivateKey&stapler-class=org.jenkinsci.plugins.plaincredentials.impl.FileCredentialsImpl&%24class=org.jenkinsci.plugins.plaincredentials.impl.FileCredentialsImpl&_.scope=GLOBAL&_.secret=$ENCODED_SECRET_TEXT&_.id=$SECRET_ID&_.description=&stapler-class=org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl&%24class=org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl&stapler-class=org.jenkinsci.plugins.docker.commons.credentials.DockerServerCredentials&%24class=org.jenkinsci.plugins.docker.commons.credentials.DockerServerCredentials&stapler-class=com.cloudbees.plugins.credentials.impl.CertificateCredentialsImpl&%24class=com.cloudbees.plugins.credentials.impl.CertificateCredentialsImpl&Jenkins-Crumb=$JENKINS_CRUMB_STRIPPED&json=%7B%22%22%3A+%225%22%2C+%22credentials%22%3A+%7B%22scope%22%3A+%22GLOBAL%22%2C+%22secret%22%3A+%22$ENCODED_SECRET_TEXT%22%2C+%22%24redact%22%3A+%22secret%22%2C+%22id%22%3A+%22$SECRET_ID%22%2C+%22description%22%3A+%22%22%2C+%22stapler-class%22%3A+%22org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl%22%2C+%22%24class%22%3A+%22org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl%22%7D%2C+%22Jenkins-Crumb%22%3A+%22$JENKINS_CRUMB_STRIPPED%22%7D&Submit=Create"
