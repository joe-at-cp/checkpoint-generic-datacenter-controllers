# Check Point Generic Cloud Datacenter Controllers

| Platform | Datacenter Controller Script |
|----------|-----------------------|
| IBM Cloud VPC Gen 2 | ibmcloud_vpc_datacenter.sh | 



## Usage
Add Datacenter Region: ./datacenter_controller.sh -add ibm --region us-south --url /var/tmp/ibm-us-south.json -p /var/tmp/ibmcloud_vpc_datacenter.sh --interval 120 <br>
Delete Datacenter Region: ./datacenter_controller.sh -delete ibm --region us-south --url /var/tmp/ibm-us-south.json <br>


