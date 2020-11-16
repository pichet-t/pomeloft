Regarding the assignment below response has been made in aws_pomelo.tf terraform file.

 * Additional non-default VPC with internet gateway and route table - created
 * Private and Public Subnets - created
 * SSH Key Setup - created
 * Virtual Compute instances that run a web service - created 
 * Virtual Compute instances that run a database - RDS created
 * Render a simple website that shows information being either pulled out of the data layer or from some 3rd party API - created, not pass connect to RDS test.    
 * Logging enabled to a central place - not start

All done in one terraform file, no actions based build workflow. Results of terraform apply are in applied.results.

Simple website is public_dns from Elastic IP below, please sign up by "I need an account" then sign in to create chat rooms.

    id                = "eipalloc-00d30385cf5130a25"
    instance          = "i-0c5b875d5e182627e"
    network_interface = "eni-0839d83996ec14531"
    private_dns       = "ip-192-168-1-77.ec2.internal"
    private_ip        = "192.168.1.77"
    public_dns        = "ec2-34-200-119-206.compute-1.amazonaws.com"
    public_ip         = "34.200.119.206"

All remarks provisioners in aws_pomelo.tf are not pass the test.
