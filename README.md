# Check Point Generic Cloud Datacenter Controllers

## How does it work?
These scripts use the generic datacenter objects introduced in Check Point version R81. All scripts are designed to run directly from the Check Point Management Server. Each datacenter script will query using native platform APIs to gather a list of all instances in a given region. This list of instances is represened as a JSON file per region. Each region is monitored for changes on an interval (in seconds) and updates are provided to the Check Point manager and pushed to enforcing gateways. Each datacenter script gets integrated into the Check Point Watchdog process to ensure they stay running and up to date. A log of updates can be found in /var/log/datacenter.log. When adding new datacenters using the datacenter_controller.sh script there is no need to add the cloud datacenter object in Smart Console, the script will add this automatically.
<br>
| Platform | Datacenter Controller Script |
|----------|-----------------------|
| IBM Cloud VPC Gen 2 | ibmcloud_vpc_datacenter.sh | 
<br>

## Usage

### Add Datacenter Region: <br> 
./datacenter_controller.sh -add ibm --region us-south --url /var/tmp/ibm-us-south.json -p /var/tmp/ibmcloud_vpc_datacenter.sh --interval 120 <br>
<br>
### Delete Datacenter Region:<br>
./datacenter_controller.sh -delete ibm --region us-south --url /var/tmp/ibm-us-south.json <br>


