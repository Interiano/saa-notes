EFS - Elastic File System

use case: content management, web serving, data sharing, wordpress

uses: NFSv4.1 protocol
    NFSv4.1 protocol is a network file sharing protocol that allows multi
    computers to access the same files over a network as if they were
    stored locally. it's the protocol amazn efs uses under the hood
    to mount shared file systems across multiple ec2 instances simultaneously

uses security group to control access to EFS

compatible with linux based AMI (not windows)

encryption at rest using KMS

POSIX file system (~linux) that has a standard file API

scales automatically

EFS - Performance and Storage Classes

EFS Scale
1000s of concurrent NFS clients, 10GB+ /s thoughput
grow to petabyte scale network file system automatically

performance mode
    general purpose
    max i/o

throughput mode
    enhanced - 
    bursting - 1 tb = 50MiB/s + burst up to 100MiB/s - thruouput scale with storage you are using
    provisoned - set your throughput regardless of storage size
    elastic - auto scale throughput up or down based on workloads
        great for unpredictable workloads

EFS - Storage Classes

Storage tiers (lifecycle management feature - move file after N days)
    standard: for frequently accessed files
    infrequent access (EFS-IA): cost to retrieve files, lower
        price to store
    archive: rarely accessed data (few times each year), 50% cheaper
    implement lifecycles policies to move files between storage tiers

Availability and durability
    standard: multi-az, gread for production
    one zone: one az, great for dev, backup enabled by default, compatible with IA (EFS One Zone-IA)

EBS vs EFS - Elastic Block Storage

EBS volumes
    locked at the az level
    one instance (except multi-attach io1)
to migrate an ebs volume across az
    take snapshot
    restore the snashot on to other AZ
    EBS backsups us IO and you shouldn't run team while application is handling a lot of traffic

root ebs volumes of instances get terminated by default if the EC2 Instances gets terminated (you can disable that)

EBS vs EFS - Elastic File Stystem

mount 100s of instances across AZ
EFS share website files (wordpress)
only for linux instances (POSIX)

efs has higher price point than EBS
can leverage Storage Tiers for cost savings

IOPS of 310,000 - you need instance store. 
data deletes on stopping however..
you can set up a replication mechanism on another ec2 instance with an instance store to have a standby copy. another solution is to set up back up mechanisms for your data.

5/25/26

Scalability & High Availability
scalability means that an application / system hand handle greater loads by adapting
scalability:
    horizontal (=elasticity) - load balancer
    vertical - t2.nano to a 12tbl.metal in a short amount of time

High Availability
    in atleast 2 AZ

Load Balancer
    server to forward traffic to multiple backend instances/servers

use case:
    spread load across multiple downstream instances
    expose a single point of access to your application
    seamlessly handle failures of downstream instances
    regular health checks to your instances
    provide ssl termination (https) for your websites
    enforce stickiness with cookies
    high availability across zones
    separate public traffic from private traffic

Elastic Load Balancer - managed load balancer
    aws guarantees that it will be working
    aws takes care of upgrades
    aws provides only a few configuration knobs

integrated with other aws offerings/services
    ec2, ag, ecs
    aws certifivcate manager acm, cloudwatch

Health Checks
    critical for load balancing
    check is done onn a port and route (/health is common)

4 types of load balancer on aws
    classic load balancer - http, https, tcp, ssl, clb
    application load balancer = http, https
    network load balancer - udp, tcp, tls
    gateway load balancer - operates at layer 3 (network layer) - ip protocol

some load balancers can be setup as internal (private) or external (public) ELBs

security groups
    a security feature is set up the load balancer to be the point of contact for your backend. 
    add application security group: allow traffic only from load balancer
        copy sg id and apply it to the instance.

Application Load Balancer (v2)
    application load balancers is layer 7 (http) - level 7 means highest level. can read
        and access files
    load balancing to multiple http applications across machines (target groups)
    load balance to multi app on the same machine (containers)
    support for http/2 and websocket
    support redirects (from http to https for example)
    support routing tables to different target groups:
        routing based on path in url (example: /users & /posts)
        routing based on hostname in url (example: one.example.com & other.example.com)
        routing based on query string, headers (example: id=123&order=false)
    
    alb are a great fit for micro services & container-based application (example: docker & ecs)
    has a port mapping feature to redirect to a dynamic port in ecs

Application Load Balancer (v2) Target Groups
    EC2 Instances (can be managed by an auto scaling group) - http
    ecs Tasks - managed by ecs itself - http
    lambda functions - http request is translated into json event
    ip address - must be private
    alb can route to multiple target groups
    health checks are at the target group level

5/25/26

Application Load Balancer (2v) query strings/parameters routing
    users > ?Platform=Mobile > ec2 instances 
    users > ?Platform=Desktop > whereever it needs to go

Application Load Balancer (v2) Good to Know
    fixed hostname - xxx.region.elb.amazonaws.com
    application servers dont see the ip of the client directly
        true ip of the client is inserted in the header x-forwaded-for
        we can also get Port (x-Forwarded-Port) and proto (X-Forwarded-Proto)
in summary of application load balancers.
    alb adds extra information to the http request header before forwarding it to your ec2 instance
        1 - x-fowarded-for - real client IP address
        2 - x-forwarded-port - the port the client used
        3 - x-forwarded-proto - the protocol the client used http or https

Network Load Balancer
    netwrok load balancer (layer 4) allow to:
        tcp & udp traffic (lower level)
    handle millions of request per seconds
    ultra low latency

    nlb has one static ip per az and supports assigning elastic ip

    Network Load Balancer - Target Groups
    Ec2 Instances
        nlb > traffic to instances: tcp or udp
    IP Addresses - must be private IPs
    Application Load Balancer
        NLB in front of ALB
    
    Health Checks support the tcp, https and https protocols

Gateway Load Balancer (GWLB)
    deploy, scale, and manage a fleet of 3rd party netwoprk virtual appliances in aws
        that means not owned by AWS security services that work IN aws tho
    example: firewalls, intrusion detection and prevention systems, deep packet inspection systems, payload manipulation,...

Sticky Sessions (session affinity)
    it is possible to implement stickiness so that the same client is always redirected to the same instance behind the load balancer

Cookie - how sticky sessions are enabled
    Application-based Cookies - are custom cookies    
        generated by the target
        can include any custom attributes required by the application
        cookie name must be specifified individually for each target group
        don't use: AWSALB, AWSALBAPP, or AWSALBTG(reserved for use by the ELB)

    Application cookie - generated by the load balancer
        cookie name is AWSALBAPP    

    Duration based cookies
        cookie generated by the load balancer
        cookie is AWSALB for ALB, AWSELB for CLB
        expiration date and duration by the load balancer

Cross-Zone Load Balancing - split evently across each registered instance in all AZ
Each load balancer instance distributes evenly across all registered instances in all AZ
AZ1 - lb with 2 ec2 - 50% traffic 
AZ2 - lb with 8 ec2 - 50% traffic 
10% across each instance

Without Cross-Zone Load Balancing 
Requests are distributed in the instance of the node of the Elastic Load Balancer
AZ1 - lb with 2 ec2 - 50% traffic - each instance is 25% overall traffic
AZ2 - lb with 8 ec2 - 50% traffic - each instance is 6.25% overall traffic

Application Load Balancer 
    enabled cross-zone load balancing - can be disabled at the target group level
    no charges for inter AZ data

Network Load Balancer & Gateway Load Balancer
    disabled cross-zone load balancing by default
    if you did want cross-zone balancing, you pay charges for inter AZ data if enabled

Classic Load Balancer
    disabled by default for cross-zone balancing

    no charge for inter az data

SSL/TLS 
    ssl - old and replaced
    tls - transport layer security - encryption protocol

ACM - AWS Credentials Manager
    creates TLS

ALB, NLB, & CLB - are associated with TLS and ACM
ALB is level 7 - http level - smart routing
NLB is level 4 - high performance, low latency
GLB does inspection and is on level 3.

Load Balancer - SSL Certificates

Users > HTTPS over www > load balancer > http over private vpc > ec2 instance
then
ec2 instance > HTTP over private VPC > load balancer > HTTPS (encrypted) over www > users

load balancer uses an x.509 certificate (ssl/tls server certificate) to very so 
browser can trust and start process

you can manage certificates using ACM

you can upload your own certificates
HTTPS listener:
    specify a default certificate
    add an optional list of certs to support multiple domains 
    clients can use SNI to specify the hostname they reach 
    abilitiy to specify a security policy to support older versions of SSL/TLS

SNI
    -load multi ssl cert from one web server
    -new protocol - requires the client to indicate the hostname of the target server in the initial ssl handshake
    -server will then find the correct cert or return a default

note: works for ALB, NLB, and cloudfront