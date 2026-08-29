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

Connection Draining
    - connection draining if CLB
    - deregistration delay if ALB & NLB

Auto Scaling Group
    automate the creation and termination of instances

set a minimum capacity, desired capacity, and a maximum capacity of instances 

asg works with the load balancer
elb checks health checks and passed onto asg. asg decides to not send requests

Auto Scaling Group Attributes
Launch Template
    ami + instancy type
    ec2 user data
    ebs volumes
    security groups
    ssh key pair
    iam roles for your ec2 instances
    network + subnets information
    load balancer information
Scaling Policies

Auto Scaling - CloudWatch Alarms & Scaling
    possible to scale an asg based on cloudwatch alarms
    alarn monitors a metric (such as average cpu, or a custom metric)
    metrics such as average cpu are computed for the overall asg instances
    scale-out policies (increase the number of instances)
    scale-in policies (decrease the number of instances)

Auto Scaling Groups - Scaling Policies
    Dynamic Scaling
        Target Tracking Scaling
            Simple to set up
            example: i want the average asg cpu to stay at around 40%
        Simple / Step Scaling
            When a cloudwatch alarm is triggered. cpu > 70% then add 2 units
            when cloudwatch alarm is triggered. cpu < 30% then remove one
    
    Scheduled Scaling
        anticipate a scaling based on known usage patterns
        example: increase the min capacity to 10 at 5 pm on fridays
    
    Predictive Scaling
        continously forcast load based on history
    
Good metrics to scale on
    cpu utilization everything ec2 receive request then computation is logged

    requestcountpertarget: to make sure the number of requests per ec2 instances is stable

    average network in/ out (if you're app is network bound)

    any custom metric (that you push using cloudfront)

Auto Scaling Groups - Scaling Cooldowns
    after a scaling activitiy , you are on cooldown (default 300 seconds) 5 minutes

    during cooldown, asg will not launch or terminate additional instances - allows metrics to stablizes

    advice: use a ready to use ami to reduce configuration time in order to be serving requests faster and reduce the cooldown period

Amazon RDS Overview
    RDS stands for Relational Database Service
    it's a managed DB service that use SQL? as a query language
    allows you to create db in the cloud managed by aws
        postgres
        mysql
        mariadb
        oracle
        microsoft sql server
        ibm db2
        aurora (aws proprietary db)
    
advantage over using rds vs deploying db on ec2
    rds is a managed service
        auto os patching
        continuous backups and restore to specifici timestamp(point in time restore)
        monitor dashborards
        read repllicas for improved read performance
        multi az for DR (disaster recovery)
        maintenance windows for upgrades
        scaling capability (vertical and horizontal)
        storage by ebs
you can't ssh

RDS storage auto scaling
    increase storage on your rds db instance dynamically
    rds detects you are running out of free database storage, it scales auto
    set maximum storage threshold (max limit for db storage)
automatically modify storage if:
    free storage is less than 10% of allocated storage
    low storage lasts at least 5 minutes
    6 hours have passed since last modification?

RDS Read Replicas for read scalability
    scale reads
    up to 15 read replicas
    within az, cross az or cross region
    replication is async so reads are eventually consistent
    can also be promoted to be it's own database
    applications must update the connection string to leverage read replicas

RDS read replicas - use cases
    you have a production db that is taking on normal load
    you want to run a reporting application to run some analytics
    you create a read replica to run the new workload there
    read replica are used for SELECT (=read) only kind of statements (not INSERT, UPDATE, DELETE)

RDS multi az (disaster recovery)
    sync replication to a standby instance
    when app writes to master, it also goes to the standby to be accepted
    one dns name - auto app failover to standby
    increase availabitliy
    failover in case of loss of az, loss of network, instance or storage failure
    no manual intervention in apps
    not used for scaling

rds - from single az to multi-az
    zero downtime operation - no need to stop the db
    just click on "modify" for the database
    following will happen:
        snapshot is taken
        new db is restored from the snapshot in a new az
        synchronization is established between the two db

ports per db:
mysql : 3306
postgresql : 5432
oracle : 1521
sql server : 1433
dynamodb : no port - https accessed

custom rds compatible
    oracle
    sql server

Aurora is mysql/postgresql
low friction lift and shift 
    aurora storage automatically grows in increments of 10gb, up to 256 tb

aurora is 20% more expensive but at scale, aurora is much more efficient

Aurora High Availability and Read Scaling
    6 copies of your data across 3 az
        4 copies out of 6 needed for writes
    self healing
    storage stripped across 100 volumes

one aurora instance takes writes (master)
    failover in 30 seconds

15 aurora read replicas

Aurora DB Cluster
writer endpoint - pointing to the master
failover - no prob, writer endpoint points to a different instance 

Writer Endpoint
    always pointing to master instance

Reader Endpoint
    connection load balancing

Features of Aurora
    fail over
    back up and recovery
    isolation and security
    industry compliance
    push button scaling
    auto patching with zero downtime
    advance monitor
    routine maintenance
    backtrack restore data at any point or time

Aurora Replica - Auto Scaling

Aurora Custom Endpoint
some read replicas are bigger than others
custom endpoint lets you specify instances are for specific workload

Aurora Serverless
    automated db instant and auto scale based on usage
    good for infrequent or unpredictable workloads
    no capacity planning needed
    pay per second

Global Aurora

aurora cross region read replicas
useful for disaster recovery
simple to put in place

Aurora Global Database - recommended
1 primary region - read/write
up to 10 secondary read only regions, replication lag is less than 1 second
up to 16 read replicas per secondary region
helps latency
promote another region - for disaster
typical cross-region replication takes less than 1 second

Aurora Machine Learning
    enables you to add ml based predictions to app via sql
    simple, optimized, and secure integration between aurora and aws ml services
    supported services
        amazon sagemaker - use any ml model
        amazon comprehend - sentiment analysis
        dont need ml experience
        use case: fraud detection, ads targeting, sentiment analysis, product recommendations

Babelfish for Aurora PostgreSQL
    allows aurora postgresql to understand commands targeted for ms sql server - t-sql

Aurora Database Cloning
    very fast and cost effective

RDS and Aurora Security
    at rest encryption - aws kms

Amazon ElastiCache 

ElasticCache is managed Redis
caches are in-memory db with really high performance, low latency
reduce load off db for read intensive workloads
makes application stateless
aws takes care of OS maintenance / patching, optimizations, setup, config, monitor, failure recory and backups
heavy application modifications to use

APP > amazon elasticache > rds  

application queries elasticache, if not available, get from RDS and store in ElastiCache
relieve rds
cache must have an invalidation strategy to make sure only the most current data is used in there

Stateless solution is peak optimization
user is able to log and load balancer assigns ec2 1 and user is then assigned ec2 2 on another request despite being logged into ec2 1. the state remains in the elasticache.

ElasticCache - Cache Security
ElasticCache supports IAM Authentication for Redis
IAM policies on ElastiCache are only used for AWS API-level security

Redis AUTH
    set password/token when you create cluster
    
    support ssl in flight encryption

Patterns for Elasticache - loading data into cache
    lazy loading - all the read data is cache, data can become stale in cache
    write through - add or update data in the cache when written to a db(no stale data)
    session store - store a temporary session data in a cache(using TTL features)

ElastiCache - Redis Use Case
    gaming leaderboards are computationally complex
    Redis Sorted sets guarantee both uniqueness and element ordering
    each time a new element added, it's ranked in real time, then added in the correct order

Important Ports:
FTP: 21
SSH: 22
SFTP: 22 (same as SSH)
HTTP: 80
HTTPS: 443

vs RDS Databases ports:
PostgreSQL: 5432
MySQL: 3306
Oracle RDS: 1521
MSSQL Server: 1433
MariaDB: 3306 (same as MySQL)

RDS Database can read 15 read replica

DNS Terminologies
    domain registrar: route53, godaddy
    dns records: a, aaaa, cname, ns
    zone file: all dns records
    name server: serlves dns queries

    URL:
    top level domain (tld) : .com, .us, .gov, .org
    second level domain (sld) : amazon.com, google.com
    sub domain: www.amazon.com the www is the sub domain
    FQDN (fully qualified domain name) : api.www.amazon.com the api is the rqdn
    Protocol: HTTP

Amazon Route 53
a highly available, scalable, fully managed and authoritative DNS
    Authoritative = the customer (you) can update the DNS records
    Route 53 is also a Domain Registrar
    ability to check the health of your resources
    100% availability SLA
    53 is a reference to the traditional DNS port

Route 53 - Records
how you want to route traffic for a domain
each record contains: 
    Domain/subdomain Name 
    Record Type
    Value
    Routing Policy - how 53 responds to queries
    TTL - amount of time the record cached at dns resolvers

Route 5 3 supports the following DNS record types:
    A, AAAA, CNAME, NS

    A - maps hostname to ipv4 - google.com -> 1.02.83.94
    AAAA - maps hostname to ipv6
    CNAME - maps a hostname to another hostname
        the target is a domain name which must have an A or AAAA record
        can't create a CNAME record for the top node of a DNS namespace (Zone Apex)
        example: can't create for example.com but you can create for www.example.com
    NS - Name Servers for the hosted zone
        control how traffic is routed for a domain
    
Route 53 - Hosted Zone
a container for records that define how to route traffic to a domain and its subdomains

public hosted zones - contains records that specify how to route traffic on the internet (public domain names)

private hosted zones - contain records that specify how you route traffic within one or more VPCS (private domain names) applicationI.comapny.internal

CNAME vs ALIAS  
cname
    point hostname to anyh other hostname
    only for non root doamin

Alias
    points a hostname to an aws resource
    works for root domain and non root
    free of charge
    innate health check

Route 53 - Alias Records
    maps a hostname to an aws resource
    an extension to dns functionality
    auto recognizes changes in the resources ip addy
    unlike cname, it can be used for the top node of a dns namespace (zone apex) e.g. example.com

Route 53 - Routing Policies
    define how route 53 responds to dns queries
    dont get confused by the word "routing"
    
Supports the following policies:
simple
weighted
failover
latency based
geolocation
multi-value answer
geoproximity - using route 53 traffic flow feature

simple routing policy - route traffic to a single resource
specify multiple values in the same record
if multiple values are returned, a random one is chosen by the client
alias enbaled, only specify one aws resource
can't associate with health checks

weighted routing policy - control the percent of the requests that go to each specific resource

assign each reacord a relative weight
    traffic% = weight for a specific record/sum of all the weights for all records
    weights dont need to sum up to 100
DNS records must have the same nameand type
can be associated with health cehcks
use cases:
    load balancing between regions, testing new app versions..
assign a weight of 0 to a record to stop sending traffic to a resource
if all records have weight of 0, then all records will be returned equally

failover
    active-passive
    associate the primary ec2 instance with the a health check/ mandatory
    if fails, reroute to standby instance
    one primary and one secondary
    DNS request will auto request healthy instance


latency based
    redirect to the resources 5that has the least latency close to us
    latency for users is a priority
    latency is based on traffic between users and AWS region
    germany users may be directed to the US - if that's the lowest latency
    can be associated with Health Checks (has a failover capability)

geolocation
    different from latency-based
    routing based on user locatiopn
    specify location by continenet, coutnry or by us state - overlapping? most precise location selected
    should create a "Default" record - in case there's no match on location
    use cases: webiste localizatiuon, restrict content distribution, load balancing...

multi-value answer
    use when routing traffic to multiple resources
    route 53 return multiple values/resources
    can be associated with health checks (return only bvalues for healthy resources)
    up to 8 healthy records are returned for each multi-value query
    multi-value is not a substitute for having an ELB

geoproximity
    route traffic based on geographic location
    ability to shift more traffic to resources based on define bias
    to change the size of the geographic region, specify bias values:
        to expand (1 to 99) more traffic to the resource
        to shrink (-1 to -9) less traffic to the resource

resources can be:
    aws resources - specify aws region
    non-aws resources - specify latitude and longtitude

you must use route 53 Traffic Flow (advanced) to use this feature

Route 53 - Health Checks
    http health check's are only for pugblic resources
    health check -> auto dns failover:
        1. health checks that monitor an endpoint - app, server, other AWS resource
        2. health checks that monitor other health checks - calculated health checks
        3. health checks that monitorv cloudwatch alarms - full control - helpful for private resources

health checks are integrated in metrics

Health Cehcks - Monitor an Endpoint
    about 15 global health checkers will check the endpoint health
        healthy/unhealthy threshold - 3 (default)
        intervalv - 30 sec (can set to 10 sec - higher cost)
        supported protocol: http, https and tcp
        if > 18% of health checkers report the endpoint is healthy, route 53 considers it healthy otherwise, it's unhealthy
        ability to choose which locations you want route 53 to use
    health checks pass only when the endpoint responds with the 2xx and 3xx status codes
    health checks can be setup to pass/fail based on the text in the first 5120 bytes of the response
    configure you router/firewall to allow incoming requests from route 53 health checkers

Routing Policies - Ip based Routing
    routing is based on client's IP address
    you provide a list of CIDR for
    your clients and corresponding endpoints/locations (user-IP-to-endpoint mappings)
    use case: optimize performance, reduce network costs...
    example: route end users from a particular ISp to a specific endpoint

Summarized Routing Policies
simple - one record, one destination. no health checks
weighted - split traffic by percentage. A/B testing, gradual deployments
latency - route to fastest aws region for that user. aws measures automatically
failover - primary and secondary. Health check fails -> route 53 switches to secondary
geolocation - route by user's country or continent. you define the rules
geoproximity - route by geographic distance. bias lets you shift traffic between regions
multi-value answer - returns multiple healthy IPs. Client picks one. Not the load balancer substitute. 
IP-based - route by client's IP address range (CIDR). Most granular control

Route 53 Resolver - Hybrid DNS
    route 53 resolver auto answers dns queries for:
        local domain names for ec2 instances
        records in private hosted zone
        records in public name servers

Hybrid DNS:
    resolving dns queries between vpc (r53 resolver) and your networks (other DNS resolvers)

Resolver Endpoint
    inbound endpoint - allows your dns resolvers to resolve domain names for aws resources ex: ec2 instances and records in private hosted zones

Route 53 - Resolver Endpoints
    Outbound Endpoint 
        R53 Resolver forwards dns queries to your dns resolver

Solutions Architecture 
Stateless Web App: WhatisTheTime.com
-dont need a db
-start small and can accept downtime
-scale vertical and horizontal, no downtimef

Route53 - ALB in public subnet - ASG in private subnet - MultiAZ in private subnet - Security Group - Alias Record - ELB Health Checks - Reservation of capacity for costing savings when possible

Stateful Web App: MyClothes.com
-shopping cart
-scale

S3 
    one of the main building blocks of aws

use cases:
    backup and storage
    disastery recovery
    archive
    hybrid cloud storage
    media hosting
    data lakes & big data anaylytics
    solftware delivery
    static websites

Amazon S3 - Buckets"
    S3 allow people to store objects(files) in "buckets" (directories)
    burckets are defined at the region level
    S3 looks lik e a global service but buckets are created in a region
    naming:
        shared global namespace -have globally unique name (across all regions all accounts)
        account regional namespace - allows for reuse of the same bucket name across regions

Amazon S3 - Objects
    object values are the content of the body:
        max objective size is 50tb
        if loading more than 5gb, must use "multi-part uplaod"
    Metadata (list of text key / value pairs - system of user metadata)
    tags (unicode key / value pair - up to 10) - useful for security / lifecycle
    Version ID (if versioning is enabled)

SAA Trivia
services:
aws lamnbda
amazon api gateway
amazon aurora

problem? 
cut costs and enhance performance with MINIMAL effort adjustments.

answer:
utilizing caching in amazon api gateway can greatly decrease the number of requests that reach your backend services by storing responses temporarily. 
great for read-heavy applications where data can be slightly outdated, as it lessens the load on the database and boosts response times, leading to cost
and performance optimizations

Amazon S3 - Security
user-based
    IAM policies - which api calls should be allowed for a specific user from iam

resource-based
    bucket policies - bucket wide rules from the s3 console - allows cross account
    object access control list ACL - finer grain - can be disabled
    bucket access control list ACL - less common - can be disabled

note: an IAM principal can access an S3 object if
    the user IAM permissions ALLOW it OR the resource policyh ALLOWS it AND there's no explicit DENY

S3 using encryption keys

S3 Bucket Policies
    JSON based policies
        resources: buckets and objects
        actions: set of api to allow or deny
        principal: the account or user to apply to the policy to
    use s3 bucket for policy to:P
        grant public access to the bucket

JSON example of giving access to the public:
{
    "Id": "Policy1665482300144",
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicRead",
            "Effect":  "Allow",
            "Principal": "*",
            "Action": [
                "s3.GetOjbect"
            ],
            "Resource": [
                "arn:aws:s3:::examplebucket/*"
            ]
        }
    ]
}

Amazon S3 - Versioning
    version your files on s3
    enabled at the bucket level
    same key overwrite will change the "version": 1,2,3...
    it is best practice to version your buckets
        protect against unintended deletes (ability to restore a version)
        easy roll back to previous version
    notes:
        any file that is not versioned prior to enabling versioning will have version "null"

Amazon S3 - Replication (CRR & SRR) - copying S3 bucket to another
    must enable Versioning in source and destination buckets
    Cross-Region Replication (CRR)
    Same-Region Replication (SRR)
    Buckets can be in different AWS accounts
    Copying is asynchronous
    Must give proper IAM permissions to S3

S3 Storage Classes
    amazon s3 standard - general purpose
    amazon s3 standard-infrequent access(IA)
    amazon s3 one zone-infrequent access
    amazon s3 glacier instant retrieval
    amazon s3 glacier flexible retrieval
    amazon s3 glacier deep archive
    amazon s3 intelligent tiering

can move between classes manually or using s3 lifecycle configurations

S3 Durability and Availability
    Durability:
        11 9's high durability = one object is lost every 10,000 years!
        all storage classes share this trait
    Availability:
        measures how readily available a service is
        varies depending on storage class
        example: s3 standard has 99.99% availability = not available 53 minutes a year

S3 Standard - General Purpose
    99.99 availability
    used for frequently accessed data
    low latency and high throughput
    sustain 2 concurrent facility failures

    use case: big data analytics, mobile & gaming applications, content distribution

S3 Storage Classes - Infrequent Access
    for data that is less frequently accessed, but requires rapid access when needed 
    lower cost than s3 standard

    Amazon S3 Standard-Infrequent Access (S3 Standard-IA)
        99.99 availability
        use cases: disaster recovery, backups
    
    Amazon S3 One Zone-Infrequent Access (S3 One Zone-IA)
        high durability in a single AZ; data lost when AZ is destroyed 
        99.5% availability
        use cases: storing secondary backup copies of on-premise data, or data you can recreate
    
    Amazon S3 Glacier Storage Classes
        low-cost object storage meant for archiving/backup
        pricing: price for storage + object retrieval cost

    Amazon S3 Glacier Instant Retrieval
        millisecond retrieval, great for data accessed once a quarter
        minimum storage duration of 90 days

    Amazon S3 Glacier Flexible Retrieval
        Expedited (1 to 5 minutes), Standard (3 to 5 hours), Bulk (5 to 12 hours) - free
        minimum storage duration of 90 days

    Amazon S3 Glacier Deep Archive - long term storaged:
        Standard (12 hours), Bulk (48 hours)
        minimum storage duration of 180 days
    
    Amazon S3 Intelligent-Tiering
        small monthly monitoring and auto-tiering fee
        moves objects auto between access tiers based on usage
        there are no retrieval charges in s3 intelligent-tiering

Amazon S3 - Moving between Storage Classes
    transition objects between storage classes
    automated with lifecycle rules

Standard > Standard IA > Inteliigent Tiering > One-Zone IA> Glacier Instant Retrieval > Glacier Flexible Retrieval > Glacier Deep Archive

transition actions - configure objects to transition to another storage class

expiration actions - configure objects to expire (delete) after some time

rules can be created for a certain prefix - example:s3//mybucket/mp3/*

rules can be created for certain objects Tags (example: Department: Finance)

scenario 2
a rule in you company states that you should be bable to recover your deleted s3 objects immediately for 30 days, although this may happen rarely. after this time, and for up to 365 days, deleted objects should be recoverable within 48 hours

solution:
enabled Versioning
Versioning allows us to incorporate delete markers
then create a rule transition the "noncurrent versions" of the object to Standard IA
transition afterwards the "noncurrent versions" to Glacier Deep Archive

Amazon S3 Analytics - Storage
this can help you decide when to transition objects to the right storage class

recommendations for Standard and Standard IA
    does not work for One-Zone IA or Glacier

report is updated daily

24 - 48 hours to start seeing data analysis

good first step to put together lifecycle rules (or improve them)

S3 - Requester Pays
    in general, bucket owners pay for all amazon s3 storage and data transfer costs associated with their bucket

    with Requester Pays
        the requester instead of the bucket owner pays the cost of the request and the data download from the bucket

    the requester must be authenticated in AWS!!

S3 Event Notifications

    S3:ObjectCreated, S3:ObjectRemoved
    object name filtering possible
    use case: generate thumbnails of images uploaded to S3
    could use it with SNS, SQS, lambda function
    delivered within seconds

in order to work
you need a IAM permission

you need these for their respected:
SNS Resource (Access) Policy
SQS Resource (Access) Policy
Lamnbda Resouce Policy 

you now use Amazon EventBridge
you can set up rules
these rules lets you send them over 18 aws services as destinations

advanced filtering options with JSON rules
mutliple destinations - step functions, kinesis stream
event bridge c apabilites -= archive, replay events, reliabvle delivery

S3 - Baseline Performance
auto scales to a high level request 100-200 ms
3500 put/copy/post/delete or 5,500 get/head request
no limits to the number of prefixes in a bucket

multi-part update

S3 transfer Acceleration
increase transfer speed by transferring file to an aws edge location which will forward the datas to the s3 bucket in the target region
compatible with multipart upload

s3 performance - s3 byte-range fetches
    parallelize get by requesting specific byte ranges
    better resilience in case of failures
    can be used to speed up downloads

    parallize the get
    order them in parts

    you can also retrieve only partial data (for example the head of the file)
    if you know that the first 50 bytes is the header

S3 Batch Operations
    perform bulk operations on existing s3 objects with a single request
    example:
        modify object metadata & properties
        copy objects between s3 buckets
        encrypt un-encrypted objects <- often tested
        modify acl's tags
        restore objects from s3 glacier
        invoke lambda function to perform custom adction on each obvject
    a job consists of a list of objects, the action to perform, and optional parameters
    S3 batch operations manages retires, tracks progress, sends completion notifications, generate reports..
    you can use s3 inventory to get object list and use Athena to query and folter your objects
    example:
        query with athena for objects not yet encrypted
        batch job to encrypt them
    
S3 Storage Lens
    understand, analyze, and optimize storage across entire aws organization
    discover anomalies, identfy cost efficiences, and apply data protection best practices across entire aws organization (30 days usage & activity metrics)

    aggregate data for organization, specific accounts, regions, buckets, or prefixes
    default dashborad or create your own dashboards
    can be configured to export metrics daily to an s3 bucket (CSV, Parquet)

Storage Lens - Metrics
summary metrics
    general insights about your s3 storage
    storagebytes, object count..
    use case: identify the fastest-gorwing (or n ot used) buckets and prefixes

cost-optimization metrics
    provide insights to manage and optimize your storage costs
    noncurrentversionstoragebytes, incompltetemultipartuploadstoragebytes...
    use case: identify buckets with incomplete multipart uplaoded older than 7 days, indentify which objects could be tgransitioned to lower-cost storage class

Data-Protection Metrics
    provides insightrs for data protection features
    versioningEnabledBuicketCo0unt, MFADeleteEnavbledBuicketCount, SSEKMSEnabledBucketCount, CrossRegionReplicationRuleCount...
    Use cases: identify buckets that aren't following data-protection best practices

Access-Management Metrics
    provide isngights for S3 Object owneership
    ObjectOwnershipBucketWonerEnforcedBucketCount...
    use case: identify which object ownership settings your buckets us

Event Metrics
    provide innghts for S3 Event Notifictaions
    EventNotificationEngabledBucketCount (indetify which bucket have S3 Event Notifications configured)
    
Performance Metrics
    provide inghts for S3 Transfer Acceleration
    TransferAccelerationEnabledBucketCount (indtify which buckets have S3 Transer Acceleration enabled)

Acitivity Metrics
    provide insights about how your storage is requested
    AllRequests, GetRequests, PutRequests, ListRequets, BytesDownloaded

Detailed Status Code Metrics
    provide insights for HTTP status codes
    200OKStatusCount, 403ForbiddenErrorCount, 404NotFoundErrorCount...

Storage Lens - Free vs. Paid
    Free Metrics
        auto available for all customaers
        contains around 28 usage metrics
        data is available for queries for 14 days
    
    Paid - Advanced Metrics and Recommendations
        additional paid metrics and features
        advanced metrics - activity, advanced cost optimization, advanced data protection, status code
        CloudWatch Publishing - access metrics in cloudwatch without additional charges
        Prefix Aggregation - Collect metrics at the prefix level
        Data is available for queries for 15 months

Amazon S3 - Object Encryption
    encrypt objects in buckets
        server=side encryuption (SSE)
            server-side Encryption with amazon s3-managed keys (SSE-S3) - by default
        server-side encryption with KMS keys sotred in aws kms (sse-kms)
            leverage aws key management serice (aws kms) to manage encryption keys
        server-side encryption with customer-provided keys (SSE-C)
            when you want to manage your own encryption keys

SSE-S3
    encryption using keys handled, managed, and owned by aws
    object is encrypted server-side
    encryption type is AES-256
    must set header to "x-amz-server-side-encryption":AES256"
    enabled by default for new buckets & new objects

Amazon S3 Encryption - SSE-KMS
    encryption using keys handled and managed by aws kms (key management service)
    kms advantages: user control + audit key usage using CloudTrail
    object is encrypted server side
    must set header "x-amz-server-sdie-encryption"

SSE-KMS Limitation
    if you use sse-kms, you may be impacted by the kms limits
    when you upload, it calls the decrypt kms api
    count towards the kms quota per second
    you can request a quota increase using the service quotas console

Amazon S3 Encryption - SSE-C
    server side encryption using keys fully managed by the customer outside of aws
    amazon s3 does not store the encryption key you provide
    https must be sued
    encryption key must provided in http headers, for every http request made

Amazon S3 Encryption - Client Side Encryption
    use client libraries such as amazon s3 client-side encryption library
    clients must encrypt data themselves before sending to amazon s3
    clients must decrypt data themeselves when retrieving from amazon s3
    client fully manages the keys and encryption cycle
    
Amazon S3 - Encryption in transit (SSL/TLS)
    encryption in flight is also called ssl/tls
    amazon s3 exposes two endpoints
        http endpoint - non encrypted
        https endpoint - encryption in flight
     https is recommended
     https is mandatory for sse-c
     most clients would use the https endpoint by default

Amazon S3 - Force Encrytpion in Transit aws:SecureTransport
    make a bucket policy
    deny any upload unless it carries an encryption

DSSE-KMS - double encryption based on KMS

What is CORS?
     cross-origin resource sharing (CORS)
     origin = scheme (protocol) + host (domain) + port
        example: https://www.example.com (implied port is 443 for https, 80 for http)
        https is the protocol, domain is www.examplel.com and the port is 80

use case:
    if a client makes a cross-origin request on our s3 bucket, we need to enable the correct CORS headers
    you can allow for a specific origin or for * (all origins)

Amazon S3 - MFA Delete
    MFA (multi factor authentication) - force users to generate a code on a device (usually a mobile phone or hardware) before doing important operations on S3
    MFA will be required to:
        permanently delete an object version
        suspend versioning on a bucket
    MFA  won't be required to:
        enabled versioning
        list deleted versions
    To use MFA Delete, Versioning must be enabled on the bucket
    Only the bucket owner (root account) can enabled/disabled MFA Delete

S3 Access Logs
    for audit purpose, you may want to log all access to s3 buckets
    any requests made to s3, from any account, authorized or denied, will be logged into another S3 bucket
    that data can be anaylyzed using data anaylysis tools...
    the target logging bucket must be in the same aws region

DO NOT USE THE SAME BUCKET FOR THE LOGGING BUCKET
WILL CREATE A LOOP

Amazon S3 - Pre-Signed URLs
generate pre-signed URLs using the S3 Console, AWS CLI or SDK
url expiration
    s3 console - 1 min up to 720 mins (12 hours)
    aws cli - configure expeiration with -expires-in parameter in seconds (default 3600 secs ~ 168 hours)
users given a pre-signed URL inherit the permissions of the user that generated the URL for GET/PUT

examples:
    allow only logged-in users to download a premium video from your S3 bucket
    allow an ever charging list of users to download files by generating URLs dynamically
    allow temporarily a user to upload a file to a precise location in your S3 bucket

S3 Glacier Vault Lock
    adopt a WORM (write once read many) model
    create a vault lock policy
    lock the policy for future edits (can no longer be changed or deleted)
    helpful for compliance and data retention
you store and can't be deleted

S3 Object Lock (versioning must be enabled)
    adopt a WORM model (write once read many)
    block an object version deletion for a specified amount of time
    retention mode - complaince:
        object versions can't be overwritten or deleted by an user, including the root user
        object retention modes can't be changed, and retention periods can't be shortened
    retention mode - governance:
        most users can't overwrite or delete an object version or alter its lock settings
        somes users have special perimissions to change the retention or delete the object
    retention period:
        protect the object for a fixed period, it can be extended
    legal hold:
        protect the object indefinitely, independent from retention period
        can be freely placed and removed using the s3:PutObjectLegalHoldIAM permission

S3 - Access Points
     simplified security management for S3 Buckets
     Each Access Point has:
        its own DNS name (internet origin or vpc origin)
        an access point policy (similar to bucket policy) - manage security at scale

S3 - Access Points - VPC Origin
    we can define the access point to be accessible only from within the VPC
    you must create a VPC Endpoint to access the Access Point (Gateway or Interface Endpoint)
    the VPC Endpoint Policy must allow access to the target bucket and Access Point

S3 Object Lambda
    use aws lambda functions to change the object before it is retrieved bvy the caller application
    only one S3 bucket is needed, on top of which we create S3 Access Point and S3 Object Lambda Access Points
    use cases:
        redacting personally identifiabled information for analytics or non=-production environments
        coverrting across data formats, such as converfstiung sml to json
        resiginzn and wattermarking images

SSE-C 
    the encryption happens in AWS and you have full control over the encryption keys

SSE-KMS
    encryption is done by AWS, keys managed by AWS, but rotation policy is in your control

Client-Side Encryption
    you have top do the encryption yourself and you have full control over the encryption keys. you perform the encryption yourself and send the encryptied data to AWS. AWS does not know your encryption keys and cannot decrypt your data

AWS CloudFront
    CDN
    improves read performance, content is cached at the edge
    hundered of points of presence globally - edge locations, caches
    ddos protection, integration with shield, aws web application firewall

CloudFront - Origins
S3 bucket
    for distributing files and caching them at the edge
    for uploading files to s3 through cloudfront
    secruted using orgin access control (oac)

VPC Origin
    for applications hosted in VPC privat e subnetts
    private application load bvalancer/ netwrok load balancer/ ec2

Custom Origin (HTTP)
    s3 website (must first enable the bucket as a static s3 website)
    any public http backend you want (example: alb)

CloudFront - ALB or EC2 as an origin
    Using VPC Origins
        allows you to deliver content fromn your applications hosted in your vpc private subnets (no need to expose them on the internet)
    deliver traffic to private:
        application load balancer
        network load balancer
        ec2 instances
    users > cloudfront (edge location) > vpc origin > private subnet (alb, nlb, ec2)

CloudFront Geo Restriction
    you can restrict who can access your distribution
        allowlist: allow your users to access your content only7 if they're in one of the countries on a list of apporoved countries
        blocklist: prevent your users from accessing your content if they're in one of the countries on a list of banned countries
    the "country" is determined using a 3rd party Geo-IP database
    use case: copyright laws to control access to content

CloudFront - Cache Invalidations
    in case you update the back-end origin, cloudfront doesn't know about it and will only get the refreshed content after the TTL has expired
    CloudFront Invalidation - force an entire or partial cache refresh (thus bypassing the TTL)
    you can invalidate all files(*) or a special path (/images/*)

problem:
    you have deployed an application and have global users who want to access it directly
    they go over the public internet, which can add a lot of latency due to many hops

new concept:
    Unicast Ip and Anycast IP

Unicast IP: one server holds one IP address

Anycast IP: all servers hold the same IP address and the clijent is routed to the nearest one

AWS Global Accelerator 
    works with Elastic IP, EC2 instances, ALB, NLB, public or private
    consistent peroformance
        intelligent routing to lowest latency and fast regional failover
        no issue with client chache (because the IP doesn't change)
        internal aws nertwork
    Health Checks
        Global Accelerator performs a health check of your applications
        Helps make your application global (failover less than 1 minute for unhealthy)
        great for disaster recovery (thanks to the health checks)
    Security
        only 2 external IP need to be whitelisted
        DDos protection thanks to aws shield
    
AWS Global Accelerator vs CloudFront
    same use of edge locations
    same aws shield

CloudFront
    improves performance for both cacheable content (such as images and videos)
    Dynamic content (such as API acceleration and dynamic site delivery)
    Content is served at the edge

Global Accelerator
    improves performance for a wide range of applications over TCP or UDP
    proxying packets at the edge to applications running in one or more aws regions
    good fit for non-http use cases, such as gaming (udp) IoT (MQTT) or Voice over IP
    good for http use cases that require static IP addresses
    good for http use cases that required deterministic, fast regional failover

Amazon FSx - Overview
    launch 3rd party high-performance file systems on AWS
    fully managed service:
        fsx for lustre
        fsx for windows file server
        fsx for netapp ontap
        fsx for openzfs
    
Amazon FSx for Windows (File Server)
    FXx for Windows is a fully managed Wiundows file system shared drive
    Supports SMB protocol & Windows NTFS
    Microsoft Active Directory integraztion, ACLs, user quotas
    can be mounsted on Linux EC2 instances
    supports microsoft's distributed file system (DFS) Namespaces (group files across multiple FS)
    scale up to 10s of GB/s, millions of IOPS, 100s PB of data
    storage options:
        SSD - latency sensitive workloads (databases, media processing, data analytics, ...)
        HDD - broad spectrum of workloads (home directory, CMS, ...)
    can be accessed from your on-premises infrastructure (vpn or direct connect)
    can be configured to be multi-az (high availability)
    data is backed-up daily to S3

SMB protocol and NFTS - 
    SMB protocol: network file sharing protocol. lets one machine access files, printers, and resrouces on another machine over a network as if it were local
    NFTS: is how windows organizes data on a local disk

things to know cold:
    fsx for windows = smb + nfts + active directory - trio identity
    fully managed windows file server
    supports multi az
    data backed by s3
    can be accessed from on premises via vpn or direct connect
    integrates with microsoft active directory or aws managed microsoft active directory

exam scenerios:
    windows workloads need shared storage -> fsx for windows
    need smb protocol ->fsx for windows (not efs)
    active directory integration required -> fsx for windows
    linux shared storage -> efs
    high performance computing/ml/video processing -> FSx for Lustre

Amazon FSx for Lustre
    Lustre is a type of parallel distributed file system, for large-scale computing
    the name Lustre is derived from Linux and cluster
    Machine Learning, High Performance Computing (HPC)
    Scales up to 100s GB/s millions of IOPS, sub-ms latencies
    Storage Options:
        SSD - low latency, IOPS intensive workloads, small & random file operations
        HDD - thoughpuyt-intensive workloads, large & sequential file operations
    Seamless integration with S3
        can read S3 as a file system (through FSx)
        can write the output of the computations back to S3 - through FSx
    can be used from on-premises servers (VPN or Direct Connect)

FSx File System Deployment Options
    Scratch File System
        temporary storage
        data is not replicated - doesn't persist if file server filas
        high burst
        usage: short-term processing, optimize costs
    Persistent File System
        long-term storage
        data is replicated within asame Az
        replace failef files within minutes
        usage: long-term processing, sensitive data

Amazon FSx for NetApp ONTAP
    managed NetApp ONTAP on AWS
    file system compatible with NFS, SMB, iSCSI protocol
    move workloads running on ONTAP or NAS to AWS
    works with:
        linux
        windows
        macos
        vmware cloud on aws
        amazon workspaces & appstream 2.0
        amazon ec2, ecs and eks
    storage shrinks or grows automatically
    snapshots, replication, low-cost, compression and data de-duplication
    point-in-time instantaneous cloning (helpful for testing new workloads)

Amazon FSx for Open ZFS
    managed openZFS file system on AWS
    file ssytem compatible with NFS (v3, v4, v4.1, v4.2)
    move workloads running on ZFS to AWS
    works with:
        linux 
        windows
        macos
        vmware cloud on aws
        amazon workspaces & appstream 2.0
        amazon ec2, ecs and eks
    up to 1,000,000 IOPS with < 0.5ms latency
    snapshots, compression and low-cost
    point-in-time instantaneous cloning (helpful for testing new workloads)

FSx for Windows - smb, ntfs, active directory, windows workloads
FSx for Lustre - hpc, ml, massive throuput, s3 integration
Fsx for NetApp ONTAP - nfs + smb + iscsi
FSx for OpenZFS - nfs only

Hybrid Cloud for Storage
    aws is pushing for "hybrid cloud"
        part of your infrastructure is on the cloud
        part of your infrastrucutre is on-premises
    the can be due to
        long cloud migrations
        security requirements
        compliance requirements
        it strategy
    s3 is a proprietary storage technology (unlike efs/nfs), so how do you expose the s3 data on-premisese
    aws storage gateway!

AWS Storage Cloud Native Options
Block - ebs and ec2 instance store
File - efs and fsx
Object - s3 and glacier

AWS Storage Gateway
    bridge between on-premises data and cloud data
    use cases:
        disaster recovery
        backup and restore
        tiered storage
        on-premises cache and low-latency files access
    
    types of storage gateway:
        s3 file gateway
        volume gateway
        tape gateway
    
AWS Storage Gateway
Amazon S3 File Gateway
    you have a bucket and it can be S3 standard, s3 standard-ia, s3 one zone-ia, s3 intelligen-tiering

    connected by a S3 File Gateway

    via NFS or SMB

    from the application server from corporate data center

Amazon S3 File Gateway
    configured s3 buckets are accessible using the nfs and smb protocol
    most recently used data is cached in the file gateway
    supports s3 standard, s3 ia, s3 one zone a, s3 intelligent tiering
    transition to s3 glacier using a lifecycle policy
    bucket access using iam roles for each file gateway
    smb protocol has integration with active directory (AD) for user authentication

Volume Gateway
    block storage using iscsi protocol backed by s3
    backed by ebs snapshots which can help restrore on-=premises volumes
    cached volumes: low latency access to most recent data
    stored volumes: entire dataset is on premise, scheduled backups to s3

Tape Gateway
    some companies have backup processes using physical tapes
    with tape gateway, companies use the same processes but, in the cloud
    Virtual Tape Library (VTL) backed by amazon s3 and glacier
    back up data using existing tape-based processes (and iSCSI interface)
    works with leading backujp software vendros

aws transfer family
    fully managed service for file transfer into and out of s3 or amazon efs using the FTP protocol
    supported protocols:
        AWS Transfer for FTP - file transfer protocol
        AWS Transfer for FTPS - file transfer protocol over SSL
        AWS Transfer for SFTP - secure file transfer protocol
    managed infrastructure, scalable, relieable, high availability (multi az)
    pay per provisioned endpoint per hour + data transfer in GB
    store and manage users credentials within the service
    integrate with existing authentication systems (microsoft active directory, LDAP, Okta, Amazon Cognito, custom)
    usage: sharing files, datasets, CRM, ERP

AWS DataSync
service appearing in exam
    move large amounts of data to and from 
        on premises/other cloud to aws (nfs, smb, hdfs, s3 api...) - needs agent
        aws to aws (different storage services - including glacier)
    can synchronize to:
        amazon s3 - any storage class - including glacier
        amazon efs
        amazon fsx (windows, lustre, netapp, openzfs)
    replication tasks can be scheduled hourly, daily, weekly
    file permissions and metadata are preserved (nfs posix, smb...)
    one agent task can use 10 gbps, can setup a bandwidth limit
    use case:
        moving data when both services are controlled by the user
        transfer family when external partners send files to you
        remember: ftp/sftp/ftps
    can be used to transfer between aws storage services
    aws datasync
    transfer between aws storage services
    s3, efs, fsx to data sync to s3, efs, fsx

Storage Comparison
    s3 - object storage
    s3 glacier - object archival
    ebs volumes - network storage for one ec2 at a time
    instance storage - physical storage for your ec2 (high iops)
    efs - network file system for linux, posix filesystem
    fsx for windows - network file system for windows servers
    fsx for lustre - high performance computing linux file system
    fsx for netapp ontap - high os compatibility
    fsx for openzfs - managed zfs file system
    storage gateway - s3 and fsx file gateway, volume gateway (cached & stored), Tape Gateway
    Transfer Family - FTP, FTPS, SFTP interface on top of s3 or efs
    DataSync - schedule data sync from on-premises to aws, or aws to aws
    Snowcone/Snowball/Snowmobile - move large amounts of data to the cloud, physically
    Database - for specific workloads, usually with indexing and querying

SQS
    managed message queue. a producer puts messages into the queue. a consumer pulls messages out and processes them. the producer and consumer never talk to each other directly - the queue sits between them. this means if the confumer is slow or down, messages just wait in the queue instead of being lost

    some mechanics:
        pull-based - consumers poll the quue, messages dont push themselves
        one consumer per message - once a consumer picks up a message and processes it, it's deleted. its not broadcast to everyone
        rentention - messages stay in the queue up to 14 days if not consumed

SNS is a pub/sub service. one message published to an sns topic gets pushed simultaneously to all subsribers. subscribers can be lambda sqs queues, email, sms, http endpoint
    sns pushes to many subscribers at once
    sqs holds messages for one consumer to pull

amazon mq 
    managed message broker service for apache active mq and rabbit mq. companies that already have on-premises apps using industry-standard messaging protocls like MQTT, AMQP, STOMP, or OPENwITE. they can't easily migrate to sqs or sns because their code is build around those protocls. amazon mq lets them lift that messaging infrastrurue into aws without rewriting their applications

new aws news:
mat cardman aws ceo
amazon quick - ai assitant for work and connects to all of them

AWS Integration & messaging
sqs, sns and kinesis

Common Infrastructure for SAA
say we'ere running an e-commerce site. traffic is unpredicatble - black friday can spike ten times overnight
users hit an application load balancer first. it distributes traffic across multiple ec2 instances and does health checks. if one instance goes down, it stops sending traffic there automatically

those ec2 instances live in an auto scaling group across two availabiltiy zones. when traffic spikes, asg launches new instances. when it drops, it terminates them.
you only pay for what you need.

the app tier talks to rds multi-az for the database. multi az means aws keeps a synchronous standby replica in a second az. if the primary fails, rds automatically fails over, no manual intervention, minimal downtime

we also add a red replica to offload read heavy traffic like product catalog browsing, so writes go to the primary and reads are distributed

traffic distribution ALB health checks and routing
instance gate security group and stateful, allow only
subnet gate nacl allow and explicit deny

Section introduction
when we start deploying multiple applications, they will inevitably need to communicate with one another
there are two patterns of application communitcations

1 synchronous communications app to app 
buying service to shipping service

2 asynchronous / event based app to queue to app
buying service to queue to shipping 

synchronous between applications can be problematic if there are sudden spikes of traffic
what if you need to suddenly encode 1000 videos but uslaly it's 10?
in that case, it's better to decouple your applications,
    using sqs: queue model
    using sns: pub/sub model
    using kinesis: real time streaming model
now these services can scale independently from our application

amazon sqs
what's a queue?

producer - can have multiple messages
consumer - pull the messages and process

buffer for decouple between consumer and producers

amazon sqs - standard queue
    older offering but still current
    over 10 years
    fully managed service, used to decouple applications

attributes:
    unlimited thoughput, unlimited number of messages in queue
    default retention of messages: 4 days, maximum of 14 days
    low latency - (10 ms on publish and receive)
    limitation of 1,024 KB per message sent

Can have duplicate messages (at least once delivery, occasionally)
Can have out of order messages - best effort ordering 

SQS - producing messages
    produced to sqs using the SDK (sendmessage api)
    the message is persisted in sqs until the consumer deletes it
    message retention: default 4 days, up to 14 days
    example: send an order to be processed
        order id
        customer id
        any attributes you want
    SQS standard: unlimited throughput

SQS - consuming messages
    consumers - running on ec2 instances, servers, or aws lambda
    poll sqs for messages - receive up to 10 messages at a time
    process the messages - ex. insert the message into an rds database
    delete the messages using the deletemessage api

sqs - multiple ec2 instances consumers
    consumers receive and process messages in parallel
    at least once delivery
    best effort message ordering
    consumers delete messages after processing them
    we can scale consumers horizontally to improve throuhput of processing

SQS with Auto Scaling Group
    ASG scaling using a metric
        CloudWatch Metric - queue length
            approximatenumberofmessages - trigger more servers to be created
            alarm for breach
            cloudwatch alarm to ASG
            ASG creates more instances

SQS to decouple between application tiers
    requests > front end web app attached auto scaling > send message to sqs >
    sqs queue > receivemessages > back end processing application (video processing) with ASG > insert to bucket

Amazon SQS - security
    encryption:
        in fligth encryption using https api
        at rest encryption using kms keys
        client side encryption if the client wants to perform encryption/decryption itself
    Acess Controls: IAM policies to regulate access to the sqs api
    SQS Access Policies - similar to s3 bucket policies
        useful for cross account access to sqs queues
        useful for allowing other services (sns, s3..) to write to an sqs queue

SQS - Message Visibility Timeout
    after a message is polled by a consumer, it becomes invisible to other consumers
    by default, the message visibility timeout is 30 seconds
    that means the message has 30 seconds to be processed
    after the message visibility timeout is over, the message is visible in sqs

there is a flaw in this system as is
if the timer for visibility starts and the message needs more than 30 seconds to process then it will re-do the same message. the fix is simple.

if a message is not processed within the visiblity timeout, it will process twice
a consumer could call the ChangeMessageVisibiloity API to get more time
if visibility timeout is high (hours), and consumer crashes, re-processing will take time
if visibility timeout is too low (seconds), we may get duplicates

Amazon SQS - Long Polling
    consumers jcan wait for a message to arrive at the sqs
    you can adjust the time of wait and optimize when a message arrives, it is ready to start without lag
    longpolling decreaases the number of api calls made to sqs while increasing the efficiency and reducing latency of your application
    long polling is preferable to short polling
    long polling can be enabled at the queue level or at the API level using WaitTimeSeconds

Amazon SQS - FIFO Queue
    FIFO = first in first out (ordering of messages in the queue)
    limited throughput: 300 msg/s without batching, 3000 msg/s with
    exactly-once send capability (by removing duplicates using Deduplication ID)
    messages are processed in order by the consumer
    Ordering by Message Group ID (all messages in the same group are ordered) - mandatory parameter

SQS with Auto Scaling Group - scale up or down
    SQS Queue -> poll for messages -> ASG with EC2 Instances
    cloudWatch Metric - Queue Length
    ApproximateNumberOfMessages is used to pull from SQS Queue 
    so CloudWatch Metric -> alarm for breach -> CloudWatch Alarm -> scale -> ASG

While that is great, a issue arises.
if the load is too big, some transactions may be lost

let's say you have RDS, Aurora, DynamoDB
and if requests come in and are handled by ASG, then more flow 
but it's too much for the back end, what to do?

SQS as a buffer to database writes
common exam pattern

same build as before but now you add an SQS Queue (infinetly scalable)
so now, the messages by the consumer are now ENQUEUE MESSAGE
adding this additional step offsets the load on orgin
so SQS Queue will receive SendMessage from the Enqueue Message Consumer
now we can Dequeue message with ASG between the SQS Queue and the Database
this covers all messages produced without dropping messages
scales on reaction to workload from CloudWatch sending messages from metrics that trigger a threshold 
this only works if the client doesn't need confirmation that it is applaying
but this is fine for this kinda of model. it will just take some time but will be completed messages

SQS to decouple between application tiers

Amazon SNS
    what if you want to send one message to many receivers?
    
SNS Security
    encrption:
        in-flight https api
        kms at rest
    
    access controls: iam pligicies to regulare access to the sns api

    snsd access policies (similar to s3 bucekt policies)
        useful for cross-account access to sns topics
        useful for allowing other services (s3...) to write to an sns topic

Application: SNS to Amazon S3 throujgh kinesis data firehose
    sns can send to kinesis and therefore we can have the following solutions architecture:
        buying service > sns topic > kinesis data firehose > s3

You can apply FIFO Topic

SNS + SQS: Fan Out
    push once in SNS Topic, receive in all SQS queues that are subscribers
    fully decoupled, no data loss
    SQS allows for: data persistence, delayed processing and retries of work
    Ability to add more SQS subscribers over time
    Make sure your SQS queue access policy allows for SNS to write
    Cross-Region Delivery: works with SQS Queues in other regions

Application: S3 Events to multiple queues
    for the same combination of: event type (object create) and prefix (images/) you can only have one S3 Event rule
    if you want to send the same S3 event to many SQS queues, use fan-out
    so in fixing:
        object created > events S3 > SNS topic > fan out to different SQS Queues, lambda functions

Application: SNS to Amazon S3 through Kinesis Data Firehose
    SNS can send to Kinesis and therefore we can have the following solutions architecture:
        buying service > sns topic > KDF > s3 or kdf destinations
    
Amazon SNS - FIFO Topic
    first in first out - ordering of messages in the topic
    similar features as SQS FIFO:
        ordering by message group id - all messages in the same group are ordered
        deduplication using a deduplication id or content based deduplication
    can have SQS Standard and FIFO queues as subscribers
    limited throughput ( same throuput as SQS FIFO)

SNS FIFO + SQS FIFO: fan out
    in case you need fan out + ordering + deduplication

SNS - message filtering
    JSON policy used to filter messages sent to SNS topic's subscriptoons
    if a subscribtiopn doesn't have a filter policy, it receives every message

    buying service > new transaction (order #, product name, qty #, state:state) > SNS Topic
    from SNS Topic > Filter Policy - State: Placed > SQS Queue - placed orders

    same infrastructure but the new transaction instead in it's json state is Cancelled
    so the filter policy directs to the sqs queue for cancelled orders

Amazon Kinesis Data Streams
    collect and store streaming data in real-time

    realtime data or iot devices or metrics/logs > producers
    producers can use a kinesis agent specific for kinesis
    you can also use applications

    that its taken to > amazon kinesis data streams > consumers
    consumers can be apps, lambda, amazon data firehose, or managed service for apache flink

Kinesis Data Stream
    data can be retained in the stream for a year
    ability to reprocess (replay) data by consumers
    data can't be deleted from kinesis (until it expires)
    data up to 10MiB(typical use case is a lot of small real time data)
    data ordering guarantee for data with the same partition id
    at rest KMS encryption, in flgith HTTTPS encryption
    kinesis producer library (KPL) to write an optimized producer application
    kinesis client library (KCL) to write an optimized consumer application

Kinesis Data Streams - capacity modes
    provisioned mode:
        choose number of shards
        each shard gets 1 MB/s in (or 1000 records per second)
        each shard gets 2 MB/s out
        scale manually to increase or decrease the number of shards
        you pay per shard provioned per hour

    on-demand mode:
        no need to provision or manage the capacity
        default capacity provioned (4 MB/s or 4000 records per second)
        scales automatically based on observed throuput peak during the last 30 days
        pay per stream per hour & data in/out per GB

Amazon Data Firehose
    point a to point b
    Producers like applications, client, sdk, kinesis agent, kinesis data streams, amazon cloudwatch, aws iot will send a record to amazon data firehose
    you can optional use a lambda function to transform
    when sending to the destination, it can also go to third party partner destination
    
    it used to be called amazon kinesis data firehose
    no longer
    fully managed service
        s3, redshift, opensearch
        third party: splunk/mongodb/datadog/newrelic
        custom http endpoint
    automatic scaling, serverless, pay for what you use

Kinesis Data Streams vs Amazon Data Firehose

    Kinesis Data Streams
        real life
        you have to add a consumer and a producer
        streaming data collection
        data stored up to one year
        replay capablity
    
    Amazon Data Firehose
        near real time
        option to use a lambda function to transform. ex. csv to json
        fully managed
        auto scaling
        doesn't support replay capability
        load streaming data into:
            s3, redshift, opensearch, third parties, custom http
        
Docker Introduction
    docker is a software development platform to deploy apps
    apps are packaged in containers that can be run on any OS
    apps run the same, regardless of where they're run
        any machine
        no compatibility issues
        preditable behaviour
        less work
        easier to maintain and deploy
        works with any language, any os, any technology
        use case: microservices architecture, lift and shift apps from on premise to the aws cloud

Docker vs Virtual Machines
    docker is a "sort of" a virtualization technology, but not exactly
    resources are shared with the host => many containers on one server

Docker Containers Management on AWS
    amazon elastic container service (amazon ecs)
        amazon's own container platform
    
    amazon elastic kubernetes service (amazon eks)
        amazon's managed kubernetes (open source)
    
    aws fargate
        amazon's own serverless container platform
        works with ecs and with eks
    
    amazon ecr
        store container images
    
Amazon ECS - EC2 Launch Type
Amazon ECS - Fargate Launch Type <- awesome appearantly 

Amazon ECS - IAM Roles for ECS
Amazon ECS - Data Volumes (EFS) - the goat move
    mount efs file systems onto ecs tasks
    works for both EC2 and Fargate launch types
    tasks running in any AZ will share the same data in the EFS file system
    Fargate + EFS = serverless
    use case:
        persistent multi-az shared storage for your containers
        note:
            S3 cannot be mounted as a file system

ECS Service Auto Scaling
    automatically increase/decrease the desired number of ECS tasks

    amazon ecs auto scaling uses aws application auto scaling
        ecs service average cpu utilization
        ecs service average memory utilization - scale on ram
        alb request count per target - metric coming from the alb
    
    target tracking - scale based on target value for a specific cloudwatch metric
    step scaling - scale based on a specified cloudwatch alarm
    scheduled scaling - scale based on a specified date/time - predictable changes

    ecs service auto scaling - task level  ITS NOT EC2 Auto Scaling - EC2 instance level
    Fargate Auto Scaling is much easier to setup - because serverless

cloudwatch metric sends a trigger to cloudwatch alarm to scale the 

Amazon EKS Overview
    amazon eks = amazon elastic kubernetes service
    it is a way to laucnh managed kubernetes clusters on aws
    kubernetes is an open source system for automatic deployment, scaling and management of containerized (usually docker) application
    it's an alternative to ecs, if you want to deploy worker nodes or Fargate to deploy serverless contgainers
    use case: if your company is already using kubernetes on premises or in another cloud, and wants to migrate to aws using kubernetes

eks and ecs are just different platforms but concept is the same
ECS---EKS
EC2 INSTANCE --- NODE
TASK --- POD
TASK DEFINITION --- POD SPEC
ECS CLUSTER --- KUBERNETES CLUSTER
ECS SERVICE --- DEPLOYMENT

Amazon EKS - Node Types
    managed node groups
        creates and manages nodes (ec2 instances) for you
        nodes are part of an asg managed by eks
        supports on-demand or spot instances
    
    self-managed nodes
        nodes created by you and registered to the eks cluister and managed by an asg
        you can use prebuil ami = amazon eks optimized ami
        supports on-demand or spot instances

    aws fargate
        no maintenance requiredp; no nodes managed
    
Amazon EKS - Data Volumes
    need to specify storageclass manifest on your eks cluster
    leverages a container storage intgerface csi compliant driver

support for...
    amazon ebs
    amazon efs - works with fargate
    amazon fsx for lustre
    amazon fsx for netapp ontap

Things to do before going to bed:
    overview of AWS Lake Formation
    overview AWS Glue
    overview S3 Apache Parquet format
    overview Amazon QuickSight
    overview OpenSearch
    overview VPC
    overview Amazon Cognito identity pool
    overview S3 access tokens
    overview Amazon Aurora DB cluster
    overview XML data

Serverless

serverless == faas

lambda by default

by default, your lambda function is launched outside your own VPC - in an aws owned vpc
therefore, it cannot access reesources in your vpc - rds, elasticache, internal elb

launch your lambda function into vpc
you need
vpc id
subnets
security group

lambda will creatd an ENI in your subnet

Lambda Function > private subnet > ENI - elastic network interface > RDS

Lambda in VPC

    you must define the vpc id, the subnets it will be on, and the security groups
    lambda will create an ENI (elastic network interface) in your subnets

just like the diagram
lambda > privatge subnet > ENI > RDS

Lambda with RDS Proxy
    rds in private gets accessed by multiple lambda requests
    the issues come with connectivity and timeouts

you can remedy this with rds proxy

Lambda with RDS Proxy
    the benefits:
        improve scalability by pooling and sharinng DB connections
        improve availability by reducing by 66% the failover time and preserving connections
        improve security by enforcing IAM authentication and storing credentials in secrets manager
    
    lambda function must be deployued in your VPC, because RDS Proxy is never publicly available

RDS Event Notifications
    notifications that tells information about the db instance itself - created, stopped, start
    you dont have any  info about the data itself
    subscribe to the follwinng event categories: db instace, db snapshot, db parameter group, db security group, rds proxy, custom engine version
    near real-time events - up to 5 minutes
    send notifications to sns or subscribe to events using eventbridge

Invoking Lambda from RDS & Aurora
    invoke lambda functions from within your db instancce
    allows you to process data events from within a database
    supported for RDS for PostgreSQL and Aurora MySQL
    must allow outbound traffic to your Lambda function from within your DB instance - public, nat gw, vpc endpoints
    db instance must have the required permissions to invoke the Lambda function - Lambda Resource-based Policy & IAM Policy

DynamoDB Accelerator (DAX)
    fully managed, highly available, seamless in-memory cache for dynamodb
    help solve read congestion by caching
    microseconds latency for cached data
    doesn't require application logic modification (compatible with exiting dynamodb apis)
    5 minutes TTL for cache (default)

DAX vs Elasticache
DAX is in front of DynamoDB, helpful for individual cache or queries and scanned queries cache
if you want to store aggregation results then amazon elasticache is better

DynamoDB - Stream Processing
    ordered stream of item-level modifications 
    use cases:
        react to changes in real time - welcome email to users
        real-time usage analytics
        inset into derivative tables
        implement cross-region replication
        invoke aws lambda on changes to your dynamodb table
    
    DynamoDB Streams
        24 hr retention
        limited # of consumers
        process using aws lambda triggers, or dynamodb stream kinesis adapter

    Kinesis Data Streams (newer)
        1 year retention
        high # of consumers
        process using aws lambda, kinesis data analytics, kinesis data firehose, aws glue streaming etl
    
DynamoDB Streams flow:
    application > create/update/delete > table > either 
    dynamodb streams or kinesis data streams
    if dynamodb streams:
        then processing layer will be either lambda or dynamodb kcl adapter
        in which case messagingin, notifications to amazon sns
        or/and
        filtering/transforming the DDB Table
        or to amazon opensearch
    if kinesis data streams:
        then it can go onto kinesis data firehose
        which can be sent to:
            anaylytics to redshift
            archiving to s3
            indexing for amazon opensearch

DynamoDB Global Tables
     make dynamodb table accessbile with low latency in multiple regions
     active-active replication
     applications can read and write to the table in any region
     must enable dynamodb streams as a pre-requisite

DynamoDB - TTL - Time To Live
auto delete items after an expiry timestamp

DynamoDB - backups for disaster recovery
    continuous backups using point-in-time recovery (PITR)
    point-in-time recovery to any time within the backup window
    the recovery process creates a new table
On-Demand backups
    full backups for long-term retention, until explicitely deleted
    doesn't affect performance or latency
    can be configured and managed in aws backup - enables cross-region copy
    the recovery process creates a new table

DynamoDB - Integration with Amazon S3
    export to s3 - must enable PITR
        works for any point of time in the last 35 days
        doesn't affect the read capacity of your table
        perform data analysis on top of DynamoDB
        rertain snapshots for auditing
        etl on top of s3 data before importing back into dynamodb
        export in dynamodb json or ion format
    
    import from s3
        import csv, dynamodb json or ion format
        doesn't consume any write capacity
        creates a new tables
        import errors logged in CloudWatch Logs

invoke a lambda function to get to dynanodb
multiple ways:
    alb between client and lambda function making it a http endpoint. it would be exposed.
    there's another way
        you can use an API Gateway
            API Gateway is a serverless offering which allows us to create REST APIs
            REST APIs
                public and accessible for our clients
                clients talk to the API gateway
                    api gateway will proxy our request to our lambda functions

Client > REST API > API gateway > proxy the request > LAMBDA > CRUD > DynamoDB

API Gateway Overview
    aws lambda + api gatewayZ: no infrastructure to manage
    support for the websocket protocol
    handle api versioning
    handle different environments (dev, test, prod...)
    handle security (authentication and authorization)
    create api keys, handle request throttling
    swagger/open api import to quickly define apis
    transform and validate requests and responses
    generate sdk and api specifications
    cache api responses

API Gateway - Integrations High Level
    lambda function 
        invoke lambda function
        easy way to expose rest api BACKEND BY AWS LAMBDA
    HTTP
        expose https endpoints in the backend
        example: internal http api on premise, application load balancer...
        why? add rate limiting, caching, user authentications, api keys, etc...
    AWS Service
        expose any aws api through the api gateway?
        example: start an aws step function workflow, post a message to sqs
        why? add authentication, deploy publicly, rate control...
    
API Gateway - AWS Service Integration Kinesis Data Streams example

client > requests > api gateway > send > kinesis data streams > records > kinesis data firehose > json files > s3

3 ways to deploy API Gatway - Endpoint Types

API Gateway - AWS Service Integration Kinesis Data Streams example

client > requests > api gateway > send > kinesis data streams > store .json files > s3

3 ways to deploy api gateway - endpoint types
    edge optimized - default: for global clients
        requests are routed through the cloudfront edge locations - improves latency
        the api gateway still lives in only one region
    regional:
        for clients winthbikn the same region
        could manually combine with cloudfront - more control over the caching strategies and the distribution
    Private:
        can only be accessed from your vpc using an interface vpc endpoint - eni

API Gateway - Security
    user authentication through
        iam roles - useful for internal applications
        cognito - identy for external users
        custom authorizer - your own logic
    
    custom domain name https security through integration with aws certificate manager - acm
        edge optimized endpoint, then the certificate must be in us-east-1
        regional endpoint, the certificate must be in the api gateway region
        must setup CNAME or A-alias record in Route 53
    
AWS Step Functions
    build serverless visual workflow to orchestrate your lambda functions
    features: sequence, parallel, conditions, timeouts, error handling,...
    can integrate with ec2, ecs, on-premises servers, api gateway, sqs queues, etc...
    possibility of implementing human approval feature
    use cases: order fulfillment, data processing, web applications, any workflow

Amazon Cognito
    give users an identity to interact with our web or mobile application
    cognito user pools:
        sign in functionality for app users
        integrates with api gateway and application load balancer
    
    cognito identity pools - federated identity:
        provide aws credentials to users so they can access aws resources directly
        integrate with cognito user pools as an identity provider
    
    Cognito vs IAM: hundreds of users, mobile users, authenticate with SAML

Cognito User Pools (CUP) - User Features
    create a serverless database of user for your web & mobile apps
    simple login: username (or email) / password combination
    password reset
    email & phone number verification
    multi-factor authentication (mfa)
    federated identities: users from facebook, google, saml

Micro Services Architecture
    we want to switch to a micro service architecture
    many services interact with each other directly using a REST API
    each architecture for each micro service may vary in form and shape

    we want a micro-service architecture so we can have a leaner develoepement lifecycle for each service

each service scale independentaly

users talk to ELB thru https and elb to ecs to dynamodb
dns query then use Route 53
alias record back

a second service
api gateway to lambda to elasticache
lambda makes a call to ELB to get a response from elb

elb to ec2 auto scaling to rds
ec2 autoscaling - not serverless to rds
ec2 must make a call to the api gateway service

it's all interconnected

Discussions on Micro Services
you are free to design each micro se4r5vice the way you want
there's two patterns
synchronous patterns: API Gateway, Load Balancers for https
thers also
asynchronous patterns: sqs, kinesis, sns, lambda triggers (s3)

challenges:
    repeated overhead for creating each new microservice,
    issues with optimizing server density/utilization
    complexity of running multiple versions of multiple microservices simultaenously
    proliferation of client-side code requirements to inttegrate with many sepearttes services
    some of the challenges are solved by servelsss patterns;
        api gateway, lambda scale automatically and you pay per usage
        you can easily close api, repoduce environments
        generated client sdk through swagger integration for the api gateway

Software updates offloading
    we have an application running on ec2, that distributes software updates once in a while
    when a new software update is out, we get a lot of request and the content is distributed in mass over the network. tit's very costly 
    we dont want to change our application, but weant to optimize our cost and cpu, how can we do it?

    our applicature current state

Choosing the Correct Database
Database Types
RDBMS (sql/oltp): RDS, Aurora - great for joins
NoSQL database - no joins, no SQL: DynamoDB (~json), Elasticache (key/value pairs), Neptune (graphs), DocumentDB (for MongoDB), Keyspaces (for Apache Cassandra)
object Store: S3 - for big objects / glacier (for backups and archives)
Data Warehouse - sql analytics/bi: redshit olap, ahtena, emr
Search: OpenSearchj - json -0 free text, unstructured searchers
Graphs: Amazon Neptune - displays relationships between data
Ledger: amazon quantum ledger datbase
Time series: amazon timestream

Amazon RDS - Summary
Managed PostgreSQL/MySQL/Oracle/SQL Server/DB2/Custom
Provision RDS Instance Size and EBS Volume Type & Size
Auto-Scaling capability for Storage
Support for Read Replica and Multi AZ
Security through IAM, Security Groups, KMS, SSL in transit
Automated Backup with Point in time restore feature - up to 35 days
Manual DB Snapshot for longer-term recovery
Managed and Scheduled maintenance - with downtime

Amazon RDS - Summary

managed postgretsql/mysql/oracle/sql server/db2/custom
provision rds instance size and ebs volume type and size
auto scaling capabilityh for storage
support for read replica and multi az
security through iam, security groups, kms, ssl in transit
automated backup with point in time restore feature - up to 35 days
manual db snapshot for longer-term recory
manual and scheduled maintenance with downtown
Support for IAM Authentication, integration with Secrets Manager
RDS Custm for access to and customize the underlying instance - oracle and sql server
use case: store relational datasets - rdbms/oltp, perform sql queires, transactions

Amazon Aurora - Summary

Redshift Overview
    Redshift is based on PostgreSQL but doesn't use OLTP - transactional database related
    it's OLAP
        online analytical processing - analytics andf data warehousing
    10x better performance and other data warehouses, scale to PBs of data
    Columndar storage of data - instead of row based and parallel query engin
    two modes; provisioned cluster or serverless cluster
    has a sql interface for performing th e queries
    BI tools such as quicksit and tagbeau integrate with it
    vs Athena: faster queires/joins/aggregations thanks to indexes

Redshit Cluster
    leader node: for query palnningf results aggregation
    compute node: for perfomring the queries, send results to leader
    provisoned mode:
        choose instance types in advance
        can reserve instances for cost savings
    
Redshift - Snapshots and DR
    Redshift has multi-az mode for some clusters
    Snapshots are point-in-time backups of a cluster, stored internally in S3
    Snapshots are incremental - only waht has changed is saved
    you can reestore a snapshot into a new cluster
    automated: every 8 hours, every 5GB, or on a schedule. Set rentention
    Manual: snapshot is retained until you delete it

    you can configure Amazon Redshit toi automatically8 copy snapshots - automated or manual of a cluster to another aws region 

Loading data into Redshit:
Large inserts are much better
amazon kinesis data firehose > amazon redhsit clustrer - thru s3 copy 

If you wanted to insert data using the JDBC driver into Redshift Cluster, you could do so as well

Redshift Spectrum

Query data that is already in S3 without loading it 
Must have a Redshift cluster
available to start the query
The query is then submitted to thousands of Redshift Spectrum nodes

Amazon OpenSearch Service
    Amazon OpenSearch is successor to Amazon ElasticSearch
    In DynamoDB, queries only exit by primary key or indexes...
    With OpenSearch, you can search as a complement to another database
    It's common to use OpenSearch as a complement to another database
    two modes: managed cluster or servelrss cluster
    Does not natively support SQL - can be enabled via a plugin
    Ingtestion from Kinesis Data Firehose, AWS IoT, and CloudWatch Logs
    Security through Cognito & IAM, KMS encryption, TLS - on flight encryption is TLS
    Comes with OpenSearch Dashboards - visualization

QuickSight Integrations
    what can quicksight integrate with?
    RDS
    aurora
    redshift
    athena
    s3
    opensearch
    timestream

can also use third party services SaaS
can also use terdata on databases

 Today is 6/29/26
 My perspective of what I do makes more sense. It has taken a while to get to this point. I'm still far from finished. I haven't touched CI/CD or terraform. I need to increase the pace. I'm doing well. 

 Around day 120.
 I felt a little bit of confidence in what I'm doing. 

 Amazon SageMaker AI
 fully managed service for developers / data scientists to build ML models

6/30/26
shift the perspective and further dive myself into the world a step forward
the more i surround my body with themes of cloud engineer.
the less frustrated i get when i read a long problem correlation to the cloud engineer role.
with this comfort, a new mood is come
the discomfort kept me active to find why to questions
now that i've been expose to these elements more and more
my threshold is different
i feel a sense of boredom
i don't think it's a bad thing
I think I need to continue leaning into the uncomfort and dive in moreso.

work on projects now.
now's the time to start proactively get started on drawing plans
solve a real world problem
documented well - what i built and why i built it

project 01
infrastructure and automation
build a complete infrastructure with terraform
it must be 3 tier

project 02
automation and monitoring
build alerting pipeline
cpu spikes
draw.io is free

project 03
ci-cd pipeline

1. the business problem
2. the architecture
3. the key decisions
4. how to deploy it

future projects must involve ci/cd pipeline and terraform

Terraform and CI/CD Pipeline

Amazon Lex is for ASR
Connect is for call centers

Amazon Comprehend
Natural Language Processing - NLP
fully manged and serverless service
use maghine learning to find insights and relationships in text
    langauge of the text
    extract key s phrases, places, people, brands, or events
    understrnad how positive or negative the text isx
    analyzes trext using tokenization and parts of speech
    automatically organizes a collection of text files by topic

sample use cases:
    analyze customer intgeraction (emails) to find what leads to a positive or negative experience
    create and groups articles by topics that comprehend will uncover

Amazon Comprehend Medical
    Amazon Comprehend Medical detects and returns useful information in unstractured clinical text:
    Phyusicisnas notes
    dishcharge summaries
    text results
    case notes

Uses NLP to detedct protected health information - phi - detectphi api

sotre your documetns in s3, analyze real-time data with kinesis Data Firehose, or use Amazon Transcibe to transcibe patient narrativews into text that can be analyzed by Amazon comprehend medical

Amazon Kendra
    fully managted document search service powered by machine learning
    extract answers from within a document - text, pdf, html, powerpoint, ms word, faq
    natural language search cababilities
    learn from user interactions/feedback to promote preffered results - incremental learning

CloudWatch Logs
    Log groups: arbitrary name, usually represneting an application
    Log stream: instances within application/log files/containers
    Can define log expeiration policies - never expire, 1 day to 10 years...
    CloudWatch Logs can send logs to:
        Amazon S3 - exports
        Kinesis Data Streams
        Kinesis Data Firehose
        AWS Lambda
        OpenSearch
    Logs are encyrpted by default
    can setup kms-based encry ption with your own keys

CloudWatch Logs - Sources
    SDK, CloudWatch Logs Agent, CloudWatch Unified Agent
    Elastic Beanstalk: collection of logs from application
    ECS: collection from containers
    AWS Lambda: collection from function logs
    VPC Flow Logs: VPC specific logs
    API Gateway
    CloudTrail based on filter

CloudWatch Logs can be sent to S3 (exports) or Amazon Data Firehose or Amazon Data Stream. or Lambda, or OpenSearch

CloudWatch Logs - Sources
SDK, ClouidWatch Logs Agent, CloudWatch Unified Agent
Elastic Beanstalk: collection of logs from application
ECS: collection from containers
AWS Lambda: collection from function logs
VPC Flow Logs: VPC specific logs
API Gateway
CloudTrail based on filter
Route 53: Log DNS queries

CloudWatch Logs Insights
    search and analyze log data stored in CloudWatch Logs
    Example: find a specific IP inside a log, count occurrences of "ERROR" in your logs...
    Provides a purpose-built query language
        automatically discovers fileds from AWS services and JSON log events
        fetch desired event fields, filter based on conditions, calculate aggregate statistics, sort events, limit number of events..
        Can save queires and add them to CloudWAtch Dashboards
    Can query multiple Log Groups in different AWS accounts
    It's a query engine, not a real-time engine

CloudWatch Logs - S3 Export
    batch export can take up to 12 hours to become available
    the API call is CreateExportTask

CloudWatch Logs Aggregation Multi-Account & Multi Region

CloudWatch Network Synthetic Monitor
    monitor and detects network issues between your apps hosted on AWS and your on-premises data center
    identify any network performance degradation - packet loss, latency, jitter..
    no agnets required to be installed
    tests icmp or tcp traffic to ipv4/ipv6 on-premises destinations through Direct Connect or S2S VPN connections
    publishes data to CloudWatch Metrics

CloudWatch Container Insights
    collect, aggregate, summarize metrics and logs from containers
    available for containers on...
        ecs
        eks
        kubernetes platforms on ec2
        fargate - both ecs and eks
    
CloudWatch Lambda Insights
    monitoring and troubleshooting solution for serverless applications running on AWS lambda
    collects, aggregates, and summarizes sytem-level metrics including CPU time, memory, disk, and network
    collects, aggregates, and summarizes diagnostic information such as cold starts and lambda worker shutdowns
    lambda insights is provided as a lambda layer

CloudWatch Lambda insights
    monitoring and troubleshooting solution for serverless applications running on AWS lambda
    collects, aggregates, and summarizes system-level metrics including CPU time, memory, disk, and network
    collects, aggregates, and summarizes idagnostic information such as cold starts and Lambda worker shutdowns
    Lambda Insights is provided as a Lambda layer

CloudWatch Contributor Insights
    analyze log data and create time series that display contributor data
        see metrics about the top-N contributors
        the total number of unique contributors, and their usage
    this helps you find top talkers and understand who or what is impacting system performance
    works for any AWS-generated logs - VPC, DNS, etc
    for example, you can find bad hosts, identify the heaviest netwrok users, or find the URLS that generate the most errors
    you can build your rules from scratch, or you can also use sample rules that aws has created - leverages your CloudWatch Logs
    CloudWatch also provides built-in rules that you can use to analyze metrics from other AWS services

    VPC > CloudWatch Logs > CloudWatch Contributor Insights > Top 10 IP addresses

    CloudWatch Application Insights
        provides automated dashboards that show potential problems with monitored applications, to help isolate ongoin issues
        your applications run on Amazon EC2 Instances with select technologies only - java, .net, microsoft iis web server, databases
        and you can use other aws resources such as amazon ebs, rds, elb, asg, lambda, sqs, dynamoDB, S3 bucket, ECS, EKS, SNS, API gateway

        powered by SageMaker
        enhanced visibility into your application health to reduce the time it will take you to troubleshoot and repair your application

CloudTrail Events
    management events:
        operations that are performed on resources in your aws account
            examples: 
                configuring security - IAM AttachRolePolicy
                configuring rules for routing data - amazon ec2 CreateSubnet
                setting up logging - AWS CloudTrail CreateTrail
            
        by default, trails are configured to log management events

AWS Organizations
    global service
    allows to manage multiple aws accounts
    the main account

CI/CD deployment
    AWS native tools mapping to each step:
        code lives in CodeCommit - or github
        CodePipeline orchestrates thew whole flow
        CodeBuild runs the tests and builds the artifact
        CodeDeploy pushes the verified build to EC2, Lambda, or ECS

Declarative - you describe the desired end state and the tool figures out waht needs to change to get there
Imperative - you tell it exactly what to do step by step with no memory of what already exists

CloudFormation as the AWS native tool - YAML/JSON templates describing stacks

AWS organizations
    global service
    allows to manage multiple aws accounts
    the main account is the management account
    other accounts are member accounts
    memeber accounts can onlyh be part of one oraginition 
    conoslidated billing across all accounts - single payment mtehod
    pricng benefits from aggregatged usage - volume discount for ec2, s2..
    shared reserved instances and savings plans discounts across accounts
    api is available to automate aws account creation

with AWS organizations
the overall hierarch is trhe Root Organiational Unit (OU)
then your main account is the management account
you can create OU for Dev and another for OU for production
in the dev ou, you can have memeber accounts

for the ou in production, you can have memeber accounts and have other OU for 
HR and Finance within the OU in production.

NAT Gateway can connect an instance in a private subnet to the public internet

Session Manager or EC2 Instance Connect - you can ssh into the instance in your AWS account

I'd put a NAT Gateway in a public subnet, then add a route in the private subnet's route table 0.0.0.0./0 -> nat-gatway-id

AWS Organizations - Tag Policies

    helps you standardize tags across resources in an aws organiation
    ensure consistent tages, audit taggged resources, maintain proper resources categoriation,...
    you define tag keys and their allowed values
    helps with aws cost allocation tags and attribute-based access control
    porvent any non-compliant tagging operations on specififed services and resources - has no effect on resrouces without tags
    generate a report that lists all tagged/non-compliant resources
    use EventBridge
    
IAM Roles vs Resource-Based Policies

SAA Trivia
Alta3 Research
AWS solutions ARchitect Associate FULL EXAM with Explanations - youtube

q1 notes:
boost performance and availability of its global platform
UDP for data transmission
needs to be failover incase of regional fail/outage. 

AWS Global Accelerator
anything that uses udp
increasing speed
instant regional failover

q2 notes:
transfer 2gb compressed data file daily to amazon s3 from a remote location. what is the most efficient method to achieve this?

multi part uplaod with s3 transfer accelerator

q8 notes:
shared file system that can be accessed by both windows and linux
NTFS persmissions
Active Directory integraton

ask the vendor to deploy a network load balancer NLV in front of the amazon rds for postgresql instance and use aws privatelink to expose the NLB as an interface VPC endpoint in the firm's vpc

the most effective solution is for the vendor to set up a NLB in front of the rds for postresql insatnce and use aws privatelink to present the nlb as an interface vpc endpoint int he firm's vpc. this method provides secure and private connectivity without needing internet access, vpn, or direct connect, and it cmaintians dtat traffic within the aws instaructure, aligning with security standards

A company requires all the data stored in the cloud to be encrypted at rest. to easily integrate this with other AWS services, they must have full control over the encryption of the created keys and also the ability to immediately remove the key mateiral from AWS KMS. The solution should also be able to audit the key usage independently of AWS CloudTrail.

The solution:
use AWS Key Managment Service to create a KMS key in a custom key store and store the non-extractable key material in AWS CloudHSM.

Overall explanation
The AWS KMS custom key store feature combines the controls provided by AWS CloudHSM with the integration and ease of use of AWS KMS. You can configure your own CloudHSM cluster and authorize AWS KMS to use it as a dedicated key store for your keys rather than the default AWS KMS key store. When you create keys in AWS KMS you can choose to generate the key material in your CloudHSM cluster. KMS Keys that are generated in your custom key store never leave the HSMs in the CloudHSM cluster in plaintext and all AWS KMS operations that use those KMS keys are only performed on your HSMs.

AWS KMS can help you integrate with otheer AWS services to encrypt the data that you store in these services and control access to the keys that decrypt it. To immediately remove the key material from AWS KMS, you can use a custom key sotre. Take note that each custome key store is a ssociated with an AWS CloudHSM cluster in your AWS account. Therefore, when you create an AWS KMS Key in a custom key store, AWS KMS generates and stores the non-extractable key material for the KMS key in an AWS CloudHSM cluster that you own and manage. This is also suitable if you want to be able to audit the usage of all your keys independently of AWS KMS or AWS CloudTrail.

Since you control your AWS CloudHSM cluster, you have the option to manage the lifecycle of your KMS keys independently of AWS KMS. Here are the criteria why you might find a custom key store useful:
1. you have encryption keys that you must be safeguarded within a dedicated hardware security module HSM under your direct ontrol, adhering to strict single-tenancy requirements
2. you require the capability to promplty and independently revoke and revmove key material from AWS KMS, exercising complete control over the key lifecycle
3. your compliance obligations mandate independent auditing and monitoring of all key usage activities, beyond the logging provided by AWS KMS and AWS Cloudtrail.

A company is using AWS Fargate to run a batch job whenever an object is uploaded to an Amazon S3 bucket. The minimum ECS task count is initially set to 1 to save on costs and should only be increased based on new objects uploaded to the S3 bucket.

Which is the most suitable option to implement with the LEAST amount of effort?

goal: suitable option to implement with the LEAST amount of effort?

the solution is EventBridge and fire after detect of S3 object put operations and set the target to the ECS cluster to run a new ECS task

IAM Permission Boundaries

AWS IAM Identity Center
successor to AWS Single Sign-On

AWS IAM Identity Center is for employees
Cognito User Pools is for users for your app

IAM Identity Center
    one login, single sign-on, for all your:
        aws accounts in aws organizations
        business cloud applications
        SAML2.0enabled applications
        EC2 Windows Instances
    identity providers:
        built-in identity store in IAM Identity Center
        3rd party: Active Directory (AD), OneLogin, Okta...

Login flow
login page > user name/password > identity center > 

AWS Directory Services
aws managed microsoft ad
    create your on ad in aws, manage users locally, supports MFA
    establish trust connections with your on-premise ad as in they are shared access across the two companies

ad connector
    acts as a proxy to redirect on-premise ad, supports mfa
    user are managed on the on-premise ad

simple ad
    ad-compatbile managed directory on aws
    cannot be joined with on-premise ad

IAM Identity Center - Active Directory Setup

KMS overview

KMS Keys Types
Symmetric AES-256 keys
    single encryption key that is used to encrypt and decrypt
    aws services that are integrated with kms use symmetric CMKs
    you never get access to the KMS key unencrypted, must call KMS api to use
Asymmetric, RSA & ECC key pairs
    public(Encrypt) and Private Key (Decrypt) pair
    used for Encrypt/Decrypt, or Sign/Verify operations
    the public key is downloadable, but you can't access the Private Key unencrypted
    use case: encryption outside of AWS by users who can't call the KMS API

AWS Directory Service provides multiple ways to use Amazon Cloud Directory and Microsoft Active Directory (AD) with other aws services. Directories store information and resources. AWS Directory Service provides multiple directory choices for customers who want to use existing Microsoft AD or Lightweight Directory Access Protocol (LDAP) - aware applications in the cloud. It also offers those same choices to developers who need a directory to manage users, groups, devices, and access.

KMS key policies

Tier 1
aws owned keys
no visibility, no trail, free, not visible to kms console at all

Tier 2
AWS managed keys
can be trailed, arn naming convention is different

Tier 3
Customer managed keys
you write the key policy, you set rotation, you share across accounts. 

DynamoDB Global Tables:
fully serverless, multi-master. every region can read and write simultanerously. conflicts resolved automatically by last-writer-wins? replication is automatic - you just enable global tabless and pick your regions. no management

Aurora Global:
one primary region handles writes. all other regions are read only replicas. replication lag is under 1 second. if primary region fails, you manulally promote a secondary region to primary - it doesn't happen automatically

why not auto? is there not a way to do this autonomously

Global DynamoDB Tables can encrypt specific attributes when sending information to KMS. When we have a case of Multi-Region Key, only the primary key can decrypt the sensible attributes in the DB when looked into by the global dynamodb table in another region. In the other region, you can then make an API call to the decrypt the attribute. It's a checks and balances. 

Aurora Global and KMS Multi-Region Keys Client-Side encryption

S3 replication
when you replicate S3 bucket to another region, encryption adds complexity depending on which encryption type was used

in order to replicate with a kms key. you first mist replicate the s3 bucket. grant it iam role permission and the key 

grant the s3 replication iam role permission to decrypt with the soruce key and encrypt with the destination key
lastly, enable the option explicityly in the replicaton configuration

Projects 

Parameters Policies (for advanced parameters)
    allow to assing a TTL to a parameter (expiration date) to force updating or deleting sensitive data such as passwords

    can assign multiple policies at a time

Expiration (to delete a parameter)
ExpirationNotification (EventBridge)
NoChangeNotification (EventBridge)

They live in SSM Parameter Store

Projects

CloudHSM - integration with AWS Services

AWS Firewall Manager
manage rules in all accounts of an aws organization
security policy: common set of security rules
    waf rules - application load balancer, api gateway, cloudfront
    aws shield advaced - alb, clb, nlb, elastic ip, cloudfront
    security groups like ec2 application load balaner and eni resources in vpc
    aws network firewall - vpc level
    amazon route 53 resolver dns firewall
    policies are created at the region level

rules are applied to new resources as they are created (good for compliance) across all and future accounts in your organization

waf vs firewall manager vs shield

waf - web application firewall - layer 7 protection. anything http. filter malicious attempts. 

shield - free for everybody aws practioner. layer 3/4 protection in udp,tcp layer. for ddos attacks

Firewall Manager - 

all are comprehensive protection of your accounts

oprah gives ip addressed to my electronics. router gives ip addresses. it's like oprah. my router gives ip addresses.

route tables decide the direction
security group/nacl deny

route table match the packet's destination IP agianst the CIDR ranges in each row, then send it to that row's target (next hop)

a company plans to migrate its on-premises workload to aws. the current architecture is composed of a microsoft sharepoint server that uses a windows shared fire storage. the solutions architect needs to use a cloud storage solution that is hihgly available and can be integrated with active directory for acces control and authentication, and must be accessbiel from on -premises via adirect connection 

which of the following options can satisfy the given requirement?

provision an amazon fsx for windows file server file system and join it to an aws active directory domain

a car dealership website hosted in amazon ec2 stores car listings in an amazon aurora database managed by amazon rds. once a vehicle has been sold, its data must be removed from the current listings and forwarded to a distributed processing sytem

which of the following options can satisfay the given requirement?

aurora mysql native function to invoke an aws lambda function whenever a vhehicle listing is deleted. configure the lambda function to send thd data to an amazon sqs queue for the distributed processing system to consume

ECS or EKS
ASG
Application Load Balancer
CloudFront

Users > DNS query > Route 53 > route traffic > CloudFront > Api Gateway > 

I would use Amazon ECS or Amazon EKS for container orchestration, coupled with AWS Auto Scaling to adjust the number of instances based on CPU or custom metrics. Application load Balancers can distribute traffic, and Amazon CloudWatch can monitor and trigger scaling events.

 7/15/26
 Direct Connect (sometimes called DX)

 dedicated connection for on-premise to be physically connected via fiber cable to a DC
 private connection, doesn't touch public
 sometimes for compliance
 you need to set up a virtual private gateway on your VPC
 you access resources (S3) and private (EC2) on same connection
 use cases:
    increase bandwidth throughput - working with large data sets - lower cost

7/19/26
I finished the hardest part of VPC lecture on the SAA course. A lot feels into place now.
I've deployed a VPC with a private and public subnet. public instance and private instance. I then found out I can ssh into a private instance with an endpoint.
This was done to remedy CIDR triggering due to large number confusion. Exposure therapy is essentially what I did.
I've started to do more SAA mock exams. 
I've started youtube SAA trivia.
I have more to go over but I'm feeling strong.
I've quizzed twice and it's beenb 65% on the last one. I thought I had scored better than that honestly. I'll try again.

Network Protection on AWS
To protect network on AWS we've seen
    network access control lists (NACLs)
    Amazon VPC secuirty groups
    AWS WAF (protect against malicious requests)
    AWS Shield and AWS Shield Advanced
    AWS Firewall Manager (to manage them across accounts)

 But what if we want to protect in a sophisticated way our entire VPC?
 AWS Network Firewall
 protect your entire amazon vpc
 from layer 3 to layer 7 protection
 any direction, you can inspect
    vpc to vpc traffic
    outbound to internet
    inbound to internet
    to/from direct connect and site-to-site vpn
internally, the aws network firewall uses the aws gateway load balancer
rules can be centrally managed cross-account by aws firewall manager to apply to many vpcs

Network Firewall - Fine grained control
between layer 3 to layer 7 protection
supports 1000s of rules

Network Firewall - Fine Grained Controls
    supports 1000s of rules
        ip and port - example: 10,000s of IPs filtering
        Protocol - example: block the SMB protocol for outbound communications
        stateful domain list rule groups: only allow outbound traffic to *.mycorp.com or third-party software repo
        general pattern matching using regex

7/21/26

Disaster Recovery

any event that has a negative impact on a company's business continuity or finances is a disaster.
DR is about preparing for and recovering from a disaster
what kind of disaster recovery?
    on-premise: on-premise: traditional DR,, and very expensive
    on-premise > aws clouid: hybrid recovery
    aws cloud region a > aws cloud region b

need to define two key terms:
RPO - recovery point objective - how often do you do backups? how much of data loss are you willing to accept?
RTO - recovery time objective - when do you recover from the disaster? the point of disaster to the point of operations

Disaster Recovery Strategies

Backup and Restore
Pilot Light
Warm Standby
Hot Site/Multi Site Approach

Faster RTO ->
Backup& Restore - Pilot Light - Warm Standby - Multi Site
AWS Multi Region covers all 4

Faster RTO means less downtime

Backup and Restore
High RPO

1. Backup and Restore
RPO/RTO: hours to days - High RPO AND RTO but cheapest
Just take backups regulardly and restore when needed
Cheapest - no standby infrastructure
Slowest recovery

2. Pilot Light
RPO/RTO: tens of minutes
Core systems running at minimal capacity in DR region - like a pilot light on a gas heater, always on but not heating
Database is replicated, servers are off but AMIs are ready
Faster than backup/restore, cheaper than warm standby

3. Warm Standby
RPO/RTO: minutes
Scaaled-down but fully functional version of your system running in DR region
Flip treaffic over and scale up when disaster hits
More expensive - infrastructure always running

4. Multi-Site Active-Active
RPO/RTO: near zero 
Full production running in multiple regions simultaenously
No recovery needed - traffic just shifts
Most expensive - double the infrastructure

Disaster Recovery Tips

Backup
    ebs snapshots, rds automated backups/snapshots, etc...
    regular pushes to s3/s3 ia/glacier, lifecycle policyh, cross region replication
    from on-p-remise: snowball or storage gateway

High Availability
    use reoute 53 to migrate dns over from region to region
    rds multi-az, elasticache multi-az, efs, s3
    site to site vpn as a recovery from direct connect

Replication
    rds replication (cross region), aws aurora + global databases
    databases replication from on-premise to rds
    storage gateway

Automation
    CloudFormation/Elastic Beanstalk to re-create a whole new environment
    recover/reboot ec2 instances with CloudWatch if alarms fail
    aws lambda functrion for customized automations

Chaos
    netflix ahs a "simian-army" randomly terminating EC2

AWS Elastic Disaster Recovery (DRS)
    used to be named"CloudEndure Disaster Recovery"
    quickly and easily recover your physical, vitural, and cloud-based servers into AWS
    Example: protect your most critical databases (including oracle, mysql, and sql server), enterpirse apps(SAP), protect your data from ransomware attacks,...
    continous block-level replication for your servedrs

DMS - Database Migration Service
    Quickly and securely migrate databases to AWS, resilient, self healing
    The source database remains available during the migration 
    Supports:
        Homogenous migrations: ex Oracle to Oracle
        Heterogeneous migrations: ex Microsoft SQL Server to Aurora
    Continous Data Replican using CDC
    You must create an EC2 instance to perform the replication tasks

DMS Sources and Targets
Sources:
    on-premise and EC2 instances database: Oracle, MS SQL Server, MySQL, MariaDB, PostgreSQL, MongoDB, SAP, DB2
    Azure: Azure SQL Database
    Amazon RDS: all including Aurora
    Amazon S3
    DocumentDB

Targets:
    on-premises jand Ec2 isntances databases
    Amazon RDS
    Redshift, DynamoDB, S3
    OpenSearch Service
    Kinesis Data Streams
    Apache Kafka
    DocumentDB & Amazon Neptune
    Redis & Babelfish

AWS Schema Conversion Tool (SCT)
    Convert your Database's Schema from one egnin to another
    Example OLTP:(SQL Server or Oracle) to MySQL, PostgreSQL, Aurora
    Example OLAP: (Teradata or Oracle) to Amazon Redshift
    You do not need to use SCT if you are migrating the same DB engine
        Ex: On-Premise PostgreSQL > RDS PostgreSQL (RDS is the platform)

DMS - Continuous Replication
setting up SCT on-premise is best practice when migrating

There's a lot of specific tools depending on the DB being migrated but it's just important to know that if it's heterogeneous migration then pairing with SCT and possibly CDC? 

You can just use snapshot for most cases, i think

On-Premise strategy with AWS
    ability to download amazon linux 2 ami as VM (.iso format)
        VMWare, KVM, VirtualBox (Oracle VM), Microsoft Hyper-V
    VM Import/ Export
        Migrate existing applications into EC2
        Create a DR repository stategy for your on-premise VMs
        can export back the VMs from EC2 to on-premise
    AWS Application Discovery Service
        Gather information about your on-premise servers to plan a migration
        Server utilization and dependency mappings
        Track with AWS Migration Hub
    AWS Database Migration Service (DMS)
        replicate on-premise > aws, aws > aws, aws > on-premise
        works with various database technologies (Oracle, MySQL, DynamoDB, etc..)
    AWS Application Migration Service (MGN)
        Incremental replication of on-premise live servers to AWS

AWS Backup
    Fully managed service
    Centrally managed and automate backups across AWS services
    No need to create custom scripts and manual processes
    Supported services:
        EC2/EBS
        S3
        RDS - all dbs engines / aurora/ dynamoDB
        DocumentDB/ Amazon Neptune
        EFS/FSx (Lustre and Windows File Server)
        AWS Storage Gateway (Volume Gateway)
    Supports cross region backups
    Supports cross account backups
    Supports PITR  for supported services like Aurora
    On-Demand and Scheduled backups
    Tag-based backup policies
    you create backup policies known as Backup Plans
        Backup frequency - every 12 weeks
        Bakcup window
        Transition to Cold Storage
        Retention Period

AWS Backup Vault Lock
    enforce a WORM (write once read many) state for all backups that you store in your AWS Backup Vault
    Additional layer of defense to protect yuour backups against:
        Inadvertent or malicious delete operations
        Updates that shorten or alter retention periods
    Even the root user cannot delete backups when enabled

On-Premise and migrate to the cloud
plan your migration
use aws application discovery service
this gathers information about on-premises DC
server utilization data and dependency mapping are important for migrations

Agentless discovery  (aws agentless discovery connector)
    vm inventory, configuration, and performance history such as cpu, momery, and disk usage

Agent-based Discovery (AWS Application Discovery Agent)
    system configuration, system performance, running processes, and details of the netwrok connections between systems

    There's two different ways to go about finding out about your on-premise DC
        you can run an agent or agentless

Resulting data can be viewed within AWS Migration Hub

AWS Application Migration Service (MGN)
    Lift-and-Shift (rehost) solution which simplify migration applications to AWS
    Converts your physical, virtual, and clouidp-based servers to run natively on AWS
    Supports wide range of platforms, Operating Systems, and databases
    Minimal downtime, reduced costs

Transferring large amount of data into AWS

VMware Cloud on AWS

Event Processing

Lambda, SNS, & SQS
SQS + Lambda

7/25/26
CloudFormation - Service Role
    IAM role that allows CloudFormation to create/update/delete stack resources on your behalf
    Give ability to users to create/update/delte the stack resources even if they don't have permissions to work with the resources in the stack
    Use cases:
        you want to achieve the least previlege principle
        but you don't want to give the user all the requirec permissions to create the stack resources
    User must have iam:PassRole permissions

SES Simple Email Service
    fully managed service to send emails securely, globally and at scale
    allows inbound/outbound emails
    reputation dashboard, performance insights, anti-spam feedback
    provides statistics such as email deliveries, bounces, feedback loop results, email open
    supports DomainKeys identified mail DKIM and Sender Policy Framework SPF
    Flexible IP deployment: shared, dedicated, and customer-owned IPs
    Send emails using your ap0plication using AWS Console, APIs, or SMTP

Amazon Pinpoint
    scalable 2-way (outbounmd/inbound) marketing communications service
    supports email, SMS, push, voice, and in-app messaging 
    ability to segment and personalize messages with the right content to customers
    possibility to receive replies
    Scales to billions of messages per day
    Use cases: run campains by sending marketing, bulk, transactional SMS messages
    Versus Amazon SNS or Amazon SES
        In SNS & SES you managed each message's audience, content, and delivery schedule
        In Amaxon Pinpoint, you create message templates, delivery schedules, highly-targeted segments, and full campaigns

Unfortune Amazon Pinpoint
but with all the services it use to create, you can just use other services:
AWS End User Messaging
Amazon SES
SES Virtual Deliverability Manager 
Amazon Connect
Amazon Kinesis

the underlying knowledge you want is SES=email delivery, SNS=pub/sub + basic SMS/push fan-out, End User Messaging home.

Systems Manager - SSM Session Manager
    Allows you to start a secure shell on your EC2 and on-premises servers
    No SSH access, bastion hosts, or SSH keys needed
    No port 22 needed (better security)
    Supports Linux, macOS, and Windows
    Send session log data to S3 or CloudWatch Logs

Systems Manager - Run Command
    Execute a document (= script) or just run a command
    Run command across multiple instances (usinmg resources groups)
    No need for SSH
    Command Output can be shown in the AWS Console, sent to S3 bucket or CloudWatch Logs
    Send notifications to SNS about command status (In progress, Success, Failed, ...)
    Integrated with IAM & CloudTrail
    Can be invoked using EventBridge

Systems Manager - Patch Manager
    Automates the process of patching managed instances
    OS updates, applications updates, security updates
    Supports EC2 instances and on-premises servers
    Supports Linux, macOS, and Windows
    Patch on-demand or on a schedule using Maintenance Windows
    Scan instances and generate patch compliance report (missing patches)

Systems Manager - Maintenance Windows
    Defines a schedule for when to perform actions on your instances
    Example: OS patching, updating drivers, installing software, ...
    Maintenance Window contains
        Schedule
        Duration
        Set of registgered instances
        Set of regsitered tasks

Systems Manager - Automation
    Simplifies common maintenance and deployment tasks of EC2 instances and other AWS resources
    Examples: restart instances, creat an AMI, EBS snapshot
    Automation Runbook - SSM Documents to define actions preformed on your EC2 instances or AWS resources (pre-defined or custom)
    Can be triggered using:
        Manually using AWS Console, AWS CLI or SDK
        Amazon EventBridge
        On a schedule using Maintenance Windows
        By AWS Config for rules remediations

Cost Explorer
    Visualize, udnerstand, and manage your AWS costs and usage over time
    Create custome reports that analyze cost and usage data.
    Analyze your data at a hgih level: total costs and usagfe across all accounts
    Or Monthly, hourly, resource level granularity
    Choose an optional Savings Plan (to lower prices on your bill)
    Forecast usage up to 18 months based on previous usage

AWS Outposts

    Hybrid Cloud: businesses that keep an on-premises infrastructure alongside a cloud infrastructure
    Therefore, two ways of dealing with IT sytems:
        One for the AWS cloud (using the AWS console, CLI, and AWS APIs)
        One for their3 on-premises infrastructure
    AWS Outposts are "server racks" that offers the same AWS infrastructure, services, APIs & tools to build your own applications on-premises just as in the cloud
    AWS will setup and manage "Outposts Racks" within your on-premises infrastructure and you can start leveraging AWS services on-premises
    You are responsible for the Outposts Rack physical security

AWS Outposts
    Benefits:
        Low-latency access to on-premises sytems
        Local data processing
        Data residency
        Easier migration from on-premises to the cloud
        Fully managed service
    Some services that work on Outposts: everything
    
AWS Batch
run jobs start to finish

AWS Amplify - web and mobile applications
    A set of tools and services that helps you develop and deploy scazlable full stack web and mobile applications
    Authentication, Storage, API (REST, GraphQL), C/CD, PubSub, Analytics, AI/ML Predictions, Monitoring....
    Connect your source code from GitHub, AWS CodeCommit, Bitbcket, GitLab, or upload directly

Amplify is like the elastic beanstalk for web and mobile applications

Amplify backend
Integrates S3, cognito, appsync, api gateway, amazon sagemaker, amazon lex, lambda, dynamodb

deployed on Amplify Console and Amazon Cloudfront

connect frontend to backend using Amplify Frontend Libraries
Frontend
ios
android
flutter
ionic
next

Instance Scheduler on AWS 
    AWS solution deployed through CloudFormation (not a service)
    Automatically start/stop your AWS services to reduce costs (up to 70%)
    Example: stop comppany's EC2 instances outside business hours
    Supports EC2 instances, Ec2 Auto Scaling Groups, and RDS instances
    Schedules are manged in a DynamoDB table
    Uses resources' tags and Lambda to stop/start instances
    Supports cross-account and cross-region resources

Fun Facts
IAM policies are attached to IAM identities (users, groups, roles), not directly to EC2 instances.

WhitePaper Section Introduction
    Well Architected Framework Whitepaper
    Well Architected Tool
    AWS Trusted Advisor
    Reference architectures resources
    Disaster Recovery

Well Architected Framework General Guiding Princicples
    https://aws.amazon.com/architecture/well-architected
    Stop guessing your capacity needs - auto scaling
    Test systems at production scale - you should perform tests thru the code
    Automate to make architectural experimentation easier
    Allow for evolutionary architectures
        Design based on changing requirements
    Drive architectures using data
    Improve through game days
        Simulate applications for flash sale days

Well Architected Framework
6 Pillars
1. Operational Excellence - 11
2. Security Reliability - 10
3. Reliability - 13
4. Performance Efficiency - 8
5. Cost Optimization - 10
6. Sustainability - 6

They are not something to balance, or trade-offs, they're a synergy

AWS Well-Architected Tool
Free tool to review your architectures against the 6 pillars Well-Architected Framework and adopt architectural best practices

How does it work? 
    Select your workload and answer questions
    Review your answers against the 6 pillars
    Obtain advice:P get videos and documentations, generate a report, see the results in a dashboard
Let's have a look: https://console.aws.amazon.com/wellarchitected

AWS Trusted Advisor
    No need to install anything - high level AWS account assessment
    Analyze your AWS accounts and provides recommendation 6 categories:
        Cost optimization
        Performance
        Security
        Fault tolerance
        Service Limits
        Operational Excellence
    Business & Enterprise Support plan
        Full Se of Checks
        Programmatic Access using AWS Support API

Recommendations for Architecture: <- take a look at it for later
https://aws.amazon.com/architecture/
https://aws.amazon.com/solutions/

You can read about some AWS White Papers here:
    Architecting for the Cloud: AWS Best Practices <- More reading
    AWS Well-Architected Framework <- More reading
    AWS Disaster Recovery (https://aws.amazon.com/disaster-recovery/) <- More reading

Read each service's FAQ
https://aws.amazon.com/vpc/faqs/

Links to Whitepapers
Links to Whitepapers


1. Architecting for the Cloud: https://docs.aws.amazon.com/wellarchitected/latest/framework/welcome.html

2. Whitepapers related to Well-Architected Framework are mentioned here: https://aws.amazon.com/architecture/well-architected/

3. Disaster Recovery Whitepaper: https://docs.aws.amazon.com/whitepapers/latest/disaster-recovery-workloads-on-aws/disaster-recovery-workloads-on-aws.html

AWS now recommends a Well-Architected Framework Whitepaper: https://docs.aws.amazon.com/pdfs/wellarchitected/latest/framework/wellarchitected-framework.pdf
\


### 1. Scenario: You have a microservices application that needs to scale dynamically based on traffic. How would you design an architecture for this using AWS services?

I would design my microservices as containers, so ECS on Fargate for orchestration and AWS manages the machine. Each one is a service that keeps a desired number of tasks running and relaunches crashes. An ALB routes requests to each service via URL path. Auto Scaling raises or lowers tasks based on the number of request per task.

### 2. Scenario: Your application's database is experiencing performance issues. Describe how you would use AWS tools to troubleshoot and resolve this.

I'd begin with CloudWatch metrics to indicate the nature of the fault. We can then deduce based on the findings and implement a fix. Metrics indicate ThrottledRequests > 0 so we know this is related to DynamoDB and the deduction is exceepding capacity. We fix with on-demand or auto scaling. Metrics show throttling but low usage so we deduce hot partition and use Contributor Insights to lock in and to fix we just redesigned partition keys. Metrics show CPU high on RDS so deduce under provisioned instance or heavy query. Performance Insights can highlight heavy query and the fix would be optimize query or vertical scaling. Metrics show Database Connections near max then we deduce connection exhaustion and the fix is RDS Proxy. 

### 3. Scenario: You're migrating a monolithic application to a microservices architecture. How would you ensure smooth deployment and minimize downtime?

I would adopt a "strangler" pattern, gradually migrating components to microservices. This minimizes risk by replacing pieces of the monolith over time, allowing for testing and validation at each step.

My answer:
I would use a "strangler" pattern, gradually migrating components to microservices. This minimizes risk by replacing pieces of the monolith over time, allowing for testing and validation at each step.

### 4. Scenario: Your team is frequently encountering configuration drift issues in your infrastructure. How could you prevent and manage this effectively?

I would implement Infrastructure as Code (IaC) using AWS CloudFormation or Terraform. By versioning and automating infrastructure changes, we can ensure consistent and repeatable deployments.

My answer:
I would implement CloudFormation and it can manage configuration drifting. Configuration drifting is when the infrastructure doesn't match the code. We need to restrict manual deployment of resources and instead use templates for deployment. CloudFormation is IaC. It deploys with declarative methods.

### 5. Scenario: Your company is launching a new product, and you expect a sudden spike in traffic. How would you ensure the application remains responsive and available?

I would implement a combination of auto-scaling groups, Amazon CloudFront for content delivery, Amazon RDS read replicas, and Amazon DynamoDB provisioned capacity to handle increase load while maintaining performance.

My answer:
I would implement a combintion of auto-scaling groups, Amazon CloudFront for content delivery, Amazon RDS read replicas, and Amazon DynamoDB provisioned capacity to handle increase load while maintaining performance.

### 6. Scenario: You're working on a CI/CD pipeline for a containerized application. How could you ensure that every code change is automatically tested and deployed?

I would set up an AWS CodePipeline that integrates with AWS CodeBuild for building and testing containers. After successful testing, I'd use AWS CodeDeploy to deploy the containers to an ECS cluster or Kubernetes on EKS.

my answer:
I would set up an AWS CodePipeline that integrates with AWS CodeBuild for building and testing containers. After successful testing. I'd use AWS CodeDeploy to deploy the containers to an ECS cluster or Kubernetes on EKS.

### 7. Scenario: Your team wants to ensure secure access to AWS resources for different team members. How could you implement this?

I would use AWS Identity and Access Management (IAM) to create fine-grained policies for each team member. IAM roles and groups can be assigned permissions based on least priviledge principles.

### 8. Scenario: You're managing a complex microservices architecture with multiple services communicating. How could you monitor and trace requests across services?

I would integrate AWS X-Ray into the application to trace requests as they traverse services. This would provide insights into latency, error, and dependencies between services.

My answer:
I would integrate AWS X-Ray into the application to trace requests as they traverse services. This would provide insights into latency, error, and dependencies between services.

### 9. Scenario: Your application has a front-end hosted on S3, and you need to enable HTTPS for security. How would you achieve this?

I would use Amazon CloudFront to distrtibute content from the S3 bucket, configure a custom domain, and associated an SSL/TLS certificate through AWS Certificate Manager.

My answer:
I would use Amazon CloudFront to distribute content from the S3 bucket, configure a custom domain, and associated an SSL/TLS certificate through AWS Certificate Manager.

### 10. Scenario: Your organization has multiple AWS accounts for different environments (dev, staging, prod). How would you manage centralized billing and ensure cost optimization?

I would use AWS Organizations to manage multiple accounts and enable consolidated billing. AWS Cost Explorer and AWS Budgets could be used to monitor and optimize costs across accounts.  

My answer:


### 11. Scenario: Your application frequently needs to run resource-intensive tasks in the background. How could you ensure efficient and scalable task processing?

I would use AWS Lambda for serverless background processing or AWS Batch for batch processing. Both services can scale automatically based on the workload. 

### 12. Scenario: Your team is using Jenkins for CI/CD, but you want to reduce management overhead. How could you migrate to a serverless CI/CD approach?

I would consider using AWS CodePipeline and AWS CodeBuild. CodePipeline integrates seamlessly with CodeBuild, allowing you to create serverless CI/CD pipelines without managing infrastructure.

### 13. Scenario: Your organization wants to enable single sign-on (SSO) for multiple AWS accounts. How could you achieve this while maintaining security?

I would use AWS Single Sign-On (SSO) to manage user access across multiple AWS accounts. By configuring SSO integrations, users can access multiple accounts securely without needing separate credentials.

### 14. Scenario: Your company is aiming for high availability by deploying applications across multiple regions. How could you implement global traffic distribution?

I would use Amazon Route 53 with Latency-Based Routing or Geolocation Routing jto direct traffic to the closest jor most appropriate region based on user location.

### 15. Scenario: Your application is generating a significant amount of logs. How could you centralize log management and enable efficient analysis?

I would use Amazon CloudWatch Logs to centralize log storage and AWS CloudWatch Logs Insights to query and analyze logs efficiently, making it easier to troubleshoot and monitor application behavior.

### 16. Scenario: Your application needs to store and retrieve large amounts of unstructured data. How could you design a cost-effective solution?

I would use Amazon S3 with appropriate storage classes (such as S3 Standard or S3 Intelligent-Tiering) based jon data access patterns.  This allows for durable and cost-effective storage of unstructured data. 

### 17. Scenario: Your team wants to enable automated testing for infrastructure deployments. How could you achieve this?

I would integrate AWS CloudFormation StackSets into the CI/CD pipeline. StackSets allow you to deploy infrastructure templates to mulitple accounts and regions, enabling automated testing of infrastructure changes.

### 18. Scenario: Your application uses AWS Lambda functions, and you want to improve cold start performance. How could you address this challenge?

I would implement an Amazon API Gateway with the HTTP proxy integration, creating a warm-up endpoint that periodically invokes Lambda functions to keep them warm.

### 19. Scenario: Your application has multiple microservices, each with its own database. How could you manage database schema changes efficiently?

I would use AWS Database Migration Service (DMS) to replicate data between the old and new schema versions, allowing for seamless database migrations without disrupting application operations.

### 20. Scenario: Your organization is concerned about data protection and compliance. How could you ensure sensitive data is securely stored and transmitted?

I would use Amazon S3 server-side encryption and Amazon RDS encryption at rest for data storage. For data transmission, I would use SSL/TLS encryption for comunication between services and implement security best practices.

Day 180:
1. What does the person who started on Day 1 not understand that you understand now?
2. What was the hardest moment and what did it teach you about how you work?
3. What does cloud engineering actually feel like now versus what you imagined it would feel like?
4. What do you still not know — and are you okay with that?
5. If someone handed you a junior cloud engineering role tomorrow, what would be the first thing you'd do on the job?

1. Ai can do a lot for you. It can't make nuanced decision making. It's still dumb and requires prompts. You can create a loop method to continuous build an app but it doesn't mean it's a good app. It still requires human intellilect. So learn the infrastructure and the ideas behind the decisions that get made for the structure.
2. I need to forgive myself. I don't have the attention span others have when it comes to studying and it's why I didn't do well in school. That didn't change now that I'm much older, so i learned to forgive myself and set a pace that was both reasonable and accomplisable. Some days it was a few hours of work and other days I'd nearly spend the whole day on the compouter just looking at coding questions, aws services, as long as it was related to what I'm studying, I was interested even if it was just listening. It may feel small but they compound because it stacks on itself. 
3. I imagined knowing code by heart.  Cloud Engineering is looking at problems and fixing thru deductions. It's more detective work. 
4. I still don't know the finer details of how to deploy instractructure without a guide. I'm okay with that. I can easily read a guide.  Day 1, it would of bothered me that i wouldn't be able to deploy complex structures without knowing the steps. Today, I understand what really matters. 
5. I'd look at what the structure I'm working on is and what it takes to maintain it. ECS? EKS?  I don't know what Day 1 working as a Cloud Engineer looks like but I'd like to know what's the board I'm playing on. 

Youtube Quiz
https://www.youtube.com/watch?v=l3LMkl82asc&list=PLwRKAmP13yepycf93KO6-Efj_ai8_fBYr&index=11

SAA-Triva
1. C
A company must meet regulatory requirement to maintain point-in-time backups of its Amazon RDS for PostgreSQL in data centers that are located at least 200 miles from each other. Which option offers the simplest way to satisfy this compliance requirement?

A. Enable a Multi-AZ red replica configuration.
B. Configure a cross-Region read replica.
C. Perform snapshot copies to another AWS Region. 
D. Use Multi-AZ snapshot replication within the same Region. 

2. D
A media organization runs a multi-tier application on AWS. The web tier is deployed across two Availability Zones using an Auto Scaling group configured with the default termination policy. Currently 15 EC2 instances are active in the group. During a scale-in event, which instrances will be terminated first?

A. The EC2 instance that was launched earliest in the Auto Scaling group.
B. The instance that is nearest to the next billing hour.
C. The instance running the Availabiltiy Zone with the highest number of instances.
D. The instance associated with the oldest launch configuration or launch template version.

3. B
A company delivers a Voice over IP (VoIP) application that relies on UDP traffic. The workload runs on Amazon EC2 instances within an Auto Scaling group and is deployed in multiple AWS Regions. The company must direct users to the Region with the lowest network latency and ensure automatic failover if a Region becomes unavailable. Which solution satisfies these requirements?

A. Deploy an Application Load Balancer (ALB) with a target group linked to the Auto Scaling group. Configure each ALB as an endpoint in AWS Global Accelerator.
B. Deploy a Network Load Balancer (NLB) with a target group attached to the Auto Scaling group. Configure each NLB as an endpoint in AWS Global Accelerator.
C. Deploy a Network Load Balancer (NLB) with its target group connected to the Auto Scaling group. Create Amazon Route 53 latency-based records pointing to each NLB alias, and place an Amazon CloudFront distribution in front using the latency record as the origin.
D. Deploy an Application Load Balancer (ALB) with a target group connected to the Auto Scaling group. Create Amazon Route 53 weighted routing records for each ALB alias, and configure an Amazon CloudFront distribution using the weighted record as the origin.

4. D
A Solutions Architect is designing storage for a fleet of Linux-based seb servers. The storage must provide a shared file system interface and scale to support millions of files. Which AWS service is the most appropriate choice?

A. Use Amazon EBS volumes attached to the instances.
B. Use Amazon S3 for storing application files.
C. Use Amazon ElasticCache as shared storage.
D. use Amazon EFS to provide shared file storage.

5. B
A customer currently uses Chef for configuration management in their on-premises data center. They want to continue using their exiting Chef recipes after migrating workloads to AWS. Which AWS service is specifically built to support this requirement?

A. AWS Elastic Beanstalk
B. AWS OpsWorks
C. AWS CloudFormation
C. Amazon Simple Workflow Service

6. B
A Solutions Architect is designing a VPC where instances in a private subnet must initiate outbound IPv6 connections to the internet. The solution must automatically scale and should not introduce additional charges. Which option meets these requirements?

A. Deploy a NAT Gateway in the public subnet
B. Configure an egress-only internet gateway.
C. Launch a custom NAT instance.
D. Create a VPC endpoint for internet access.

7. C
A newly acquired subsidiary must quickly deploy its infrastructure on AWS and migrate several applications within one month. Each application includes about 50TB of data that must be transferred to AWS. After migration, both the subsidiary and its parent company require secure, reliable connectivity with predictable throuput from their on-premises data centers to AWS. Which solution best addresses both the bulk data transfer and the ongoing connectivity needs?

A. Use AWS Direct Connect for the initial large-scale data transfer and for continous connectivity.
B. Use AWS Snowball for the initial migration and AWS Site-to-Site VPN for ongoing connectivity.
C. use AWS Snowball for the one-time data migration and AWS Direct Connect for long-term connectivity.
D. Use AWS Site-to-Site VPN for both the initial migration and continuous connectivity.

8. A
A Solutions Architect is building an application that requires all stored data within an Amazon Redshift cluster to be encrypted. Which action ensures encryption of the data at rest?

A. Encrypt the cluster using an AWS KMS customer-managed or default KMS key.
B. Enable SSL/TLS for client connections to the cluster.
C. Launch the cluster inside a private subnet within a VPC.
D. Encrypt the underlying Amazon EBS volumes manually.

9. D
An Amazon EBS volume is currently attached to an EC2 instance in one Availability Zone. What is the correct method to move this volume to a different Availability Zone?

A. Detach the volume and directly attach it to an EC2 instance in the target Availability Zone.
B. Detach the volume and use an Ec2-migrate-volume command to transfer it to another Availability Zone.
C. Create a new volumen in the target Availability Zone by specifying the existing volume as the source.
D. Take a snapshot of the volume and create a new volume from that snapshot in the desired Availability Zone.

10. A
A high-traffic e-commerce application hosted on AWS is experiencing database performance bottlenecks during peak usage periods. The database runs on the Amazon Aurora engine using the largest available instance size, yet it still cannot handle the query load. What action should the administrator take the improve the performance?

A. Add one or more read replicas to the database cluster.
B. Migrate the database to Amazon Redshift.
C. Configure Amazon CloudFront in the front of the application.
D. Modify the database to use Provisioned IOPS on Amazon EBS. 

11.  B
An application requires that messages be processed strictly in the order they are sent. The expected throuput will not exceed 300 transactions per second. Which AWS service should be selected to meet these requirements?

A. Amazon SNS
B. Amazon SQS
C. Amazon ECS
D. AWS Security Token Service

12. A
A Solutions Architect is building a web application where the web and application tiers must initiate outbound internet connections (for updates or external API calls) but must not be directly reachable from the internet. Whhich configuration is required to meet these requirements?

A. Deploy a NAT Gateway in the public subnet and configure the private subnet's route table to send internet-bound traffic to it
B. Assign an Elastic IP address to each Amazon EC2 instance and routing between private and public subnets.
C. Launch the instances in a public subnet and allow outbound HTTP (port 80) traffic in the security group.
D. Deploy a NAT gateway and a NAT instance within the private subnet.

13. A & D
A Solutions Architect is developing a web application that runs on an Amazon EC2 instance and stores data in Amazon DynamoDB. The Architect must ensure secure and recommended authorization for the application to access the DynamoDB table. Which two steps should be taken? (Choose two)

A. Create an IAM role that grants write permissions to the DynamoDB table.
B. Store AWS access keys directly on the EC2 instance with permissions to access the table.
C. Attach an IAM policy directly to the EC2 instance.
D. Associate the IAM role with the EC2 instance.
E. Attach an IAM user to the EC2 instance.

14. A 
A company operates a shopping application that stores customer data in Amazon DynamoDb. To protect against accidental data corruption, the Solutions Architect must design a recovery strategy that supports a Recovery Point Object (RPO) of 15 minutes and a Recovery Time Objective (RTO) of 1 hour. Which solution should be recommended?

A. Enable DynamoDB point-in-time recovery (PITR) and restore the table to a specific timestamp when recovery is required.
B. Configure DynamoDB global tables and redirect the application to another AWS Region during recovery.
C. Perform daily exports of DynamoDB data to Amazon S3 Glacier and reload the data when recovery is needed.
D. Schedule Amazon EBS snapshots every 15 minutes and restore the DyhnamoDB table from those snapshots.

15. B
A company plans to store data in an Amazon DynamoDB table and wants to minimize costs. The workload is idle during most mornings, but in the evenings traffic becomes unpreditable with sudden and rapid spikes and read and write requests. Which solution should a Solutions Architect recommend?

A. Create the table using provisioned capacity mode and enable auto scaling. 
B. Create the table using on-demand capacity mode.
C. Create the table with provisioned capacity and configure it as a global table.
D. Create the table and add a global secondary index (GSI).

16. C
A company runs applications on Amazon EC2 instances inside a VPC. One application must interact with the Amazon S3 API to store and retreive objects. Company security policies prohibit any application traffic from traversing the public internet. Which solution satisfies this requirement?

A. Deploy a NAT gateway in the same subnet as the EC2 instances.
B. Create an S3 bucket within a private subnet.
C. Configure as S3 gateway VPC endpoint. 
D. Create the S3 bucket in the same AWS Region as the EC2 instances.

17. B
A company's application collects data from multiple SaaS providers. Currently, Amazon EC2 instances receive the incoming data, upload it to an Amazon S3 bucket for analysis, and then notify users when the upload is finished. The company is experiecing performance degradation and wants to improve performance while minimizing operational overhead. Which solution should a Solutions Architect recommend?

A. Create an Auto Scaling group for the EC2 instances to scale horizontally. Configure S3 event notifications to publish to an Amazon SNS topic when uploads complete.
B. Use Amazon AppFlow to transfer data directly from each SaaS source to the S3 bucket. Configure S3 event notifications to publish to an SNS topic when uploads complete.
C. Configure Amazon EventBridge rules for each SaaS source to send data to S3. Create another EventBridge rule to trigger an SNS notification when uploads complete. 
D. Containerize the application and run it on Amazon Elastic Container Service. Use CloudWatch Container Insights to trigger SNS notifications after S3 uploads. 

18.  B
A Solutions Architect is designing an application that must securely access data hosted in a different AWS account within the same Region. The traffic must remian private and must not traverse the public internet. Which solution provides the required connectivity at the lowest cost?

A. Configure an AWS Direct Connect connection for each account.
B. Establish a VPC peering connection between the two account's VPCs. 
C. Add a NAT gateway in the account the hosts the data.
D. Modify security group rules in both accounts to allow cross-account access.

19. A
A Solutions Architect is designing a three-tier web application that uses an Auto Scaling group of Amazon EC2 instances behind an Elastic Load Balancing Classic Load Balancer. The security team mandates that web servers must only accept traffic from the load balancer and must not be directly reachable from the internet. What configuration should be implemented to meet this requirement?

A. Configure the web tier's security group to allow inbound traffic only from the Classic Load Balancer's security group. 
B. Deploy a load balancer software solution on a seperate EC2 instance.
C. Update the web servers' security group to block all traffic originating from the public internet.
D. Place an Amazon CloudFront distribution in front of the Classic Load Balancer.

20. C
An application needs block-level storage to support frequent file updates. The total dataset size is 500 GB, and the workload must consistently sustain 100 MiB/s of combined read and write throughput. Which AWS storage service is most appropriate choice?

A. Amazon EFS 
B. Amazon S3
C. Amazon EBS
D. Amazon S3 Glacier

21. C 
A legacy application must connect to local storage using the iSCI protocol. The team wants to provision new, reliable storage on AWS maintaining compatibility with the application's exiting iSCI requirements. Which AWS storage solution should be selected?

A. Use AWS Snowball as temporary storage until the application is modernized.
B. Deploy AWS Storage Gateway in cached mode to present iSCSI volumes while storing primary data in Amazon S3.
C. Deploy AWS Storage Gateway in stored mode to provide iSCSI volumes with primary data stored locally and asynchronously backed up to Amazon S3. 
D. Mount an Amazon S3 bucket locally by using the File Gateway configuration.

22. B
A production application frequently updates and deletes records. The application must always retrieve the latest committed version of the data wheenever it is accessed. Which AWS Storage Service is the most appropriate for this requirement?

A. Amazon Redshift
B. Amazon RDS
C. AWS Storage Gateway
D. Amazon S3

23. D
A Solutions Architect is developing a feature that uses AWS Lambda to generate metadata whenever a user uploads an image to Amazon S3. The metadata must be fully indexed to allow efficient lookups and queries. Which AWS service should be used to store this metadata?

A. Kinesis
B. Amazon S3
C. Amazon EFS
D. Amazon DynamoDB 

24. B & D
A company wants to track read and write IOPS metrics for its MySQL database running on Amazon RDS and receive real-time alerts when certain thresholds are exceeded. Which two AWS services should be used to implement this monitoring and alerting solution?

A. SQS
B. Amazon CloudWatch 
C. Amazon Route 53
D. SNS
E. SES

25.  C
What is a primary distinction between an Amnazon EBS-backed EC2 instance and an instance store-backed EC2 instance?

A. Auto Scaling can only be used with EBS-backed instances
B. Instance store-backed instances support stopping and restarting
C. Amazon EBS-backed instances can be stopped and later restarted.
D. Amazon VPC requires the use of EBS-backed instances

Maarek's Udemy Practice SAA Exam Notes
1. 
structure:
ALB > ASG + REST API > DynamoDB + S3 (static image and content)
goal:
performance

12. 
structure:
AWS direct connect connection for migrating its flagship application to the AWS Cloud
what it does:
writes hundreds of video files into a mounted NFS file system daily.

Post migration, the company will host the app on an ec2 instance with a moundted efs file system.

Before the migration cutover, the company must build a process that will replicated the newly created on-premises video files to the EFS file system.

49. 
company has custom data warehousing solution using Redshift.

company wants to move any historical data (older than a year) into S3

retain the ability to cross-reference this data with daily reports

least amount of effort and minimim cost

56. 
aws cloud to manage infrastructure

9 minutes and 20 seconds left

Throttling is the process of limiting number of requests an authorized program can submit to a given operation in a given amount of time

Amaon API Gateway, SQS, Kinesis

To prevent your API from being overwhelemed by too many requests, amazon API Gateway throttles requests to your API using the token bucket algorithm, when a token counts for a request.
Specificially, API Gateway sets a limit on a steady-state rate and burst of request submissions against all APIs in your account. In the token bucket algorithm, the burst is the maximum bucket size.

Amazon SQS - fully managed message queuing service that enables you to decouple and scale microservices, distributed system, and servless applications. SQS offers buffer capabilities to smooth out temporary volume spikes without losing messages or increasing latency. 

Kinesis - fully managed, scalable service that can ingest, buffer, and process streaming data in real-time.

AWS Lambda as a backbone for the architecture. 
Key points.

Be default, AWS Lambda functions always operate from an AWS-owned VPC and hence have access to any pu9blic internet address or public AWS APIs. Once an AWS Lambda function is VPC-enabled, it will need a route through a Network Address Translation gateway (NAT gateway) in a public subnet to access public resources.

Since AWS Lambda functions can scale extremely quick, it's a good idea to deploy a Amazon CloudWatch Alarm that notifies your team when function metrics such as Concurrent Executions or Invocations exceeds the expected threshold.

If you intend to reuse code in more than one AWS Lambda function, you should consider creating an AWS Lambda Layer for the reusable code

5. 
A Big Data processing company has created a disstributed data processing framework that performs best if the network performance betwen the processing machines is high. The  application has to be deployed on AWS, and the company is only looking at performance as the key measure.

As a Solutions Architect, which deploymkent do you recommend?

Cluster Placement Group

7. 
An e-commerce company has copied 1 petabyte of data from its on-premises data center3 to an Aamzon S3 bucket in the us-west-1 Region using an AWS Direct Connect link. The company now wants to set up a one-time copy of the data to another Amazon S3 bucket in the us-east-1 Region. The on-premises data center does not allow the use of AWS Snowball.

As a Solutions Architect, which of the following options can be used to accomplish this goal? 

- Copy data from the source bucket to the destination bucket using the AWS S3 sync command
- Set up Amazon S3 batch replication to copy objects across Amazon S3 buckets in another Region using S3 console and then delete the replication configuration

8. 
The DevOps team at an IT company is provioning a two-tier applicaation in a VP:C with a public subnet and a private subnet. The team wants to use either a NAT instance or a NAT Gateway in the public subnet to enab le instances in the private subnet to initiates outbound IP:v4 traffic to the internet but needs some technical assitgance in terms of the configuartion options availbable for the NAT AINSTANCE AND THE nat GATEWAY

aS A SOLUTIONS A4RCHITCECT, which of thge following options would you identify as correct?

Security Groups can be associated with a NAT instance
NAT instance can be used as a bastion server
NAT instance supports port forwarding

10. 
A financial services company recently luanched an inititiative to improve the security of its AWS resources and it had enabled AWS Shield Advanced across multiple AWS accounts owned by the company. Up analysis, the company has found that the costs incurred are much higher than expected.

Which of the following would you attribute as the underlying reason for the unexpectedly high costs for AWS Shield Advanced service?

Consolidated billing has not been enabled. All the AWS accounts should fall under a single consolidated billing for the monthly fee to be charged only once.

11. 
A weather forecast agency collects key weather metrics across multiple cities in the US and sends this data in the form of key-value pairs to AWS Cloud at a one-minute frequency.

As a solutions architect, which of the following AWS services would you use to build a solution for processing and then reliably storing this data with high availability?

-DynamoDB
-AWS Lambda

13. 
An engineering team wants to examine the feasibility of the user data feature of Amazon EC2 for an upcoming project.
Which of the following are true about the Amazon EC2 user data configuration?

By default, scripts entered as user data are executed with root user priviledges
By default, user data runs only during the boot cycle when you first launch an instance

Reasoning:
User Data is generally used to perform common automated configuration tasks and even run scripts after the instacnce starts. When you launch an instance in Amazon EC2, you can pass two types of user data-shell scrips and cloud-init directives. You can also pass this data into the launch wizard as plain text or as a file. 

Fun Notes:
Volume Gateway (the Storage mode that presents iSCSI block volumes)
File Gateway uses NFS/SMB
Tape Gateway VTL (backup/archive)
Volume Gateway iSCSI (block)

30. 
A big data analytics company writes data and log files in Amazon S3 buckets. The company now wants to stream the existing data files as well as any ongoing file updates from Amazon S3 to Amazon Kinesis Data Streams.

writes data and log files into S3
now stream existing data files as well as ongoing file updates from S3 to Kinesis

It's the choice that takes data to migrate straight to the streams

Leverage AWS Database Migration Service (AWS DMS) as a bridge between Amazon S3 and Amazon Kinesis Data Streams

Question: What's the point of Firehose?

Kinesis Data Streams
Two modes:

1. provision mode
think of kinesis data stream is a pipeline
data comes in
producers > consumers

Inside the pipeline, there's shards.
Shards - control throughput of the pipeline
DataBlob = data payload

Producers - produce data into the stream
data packages go into the shard
record = package
In the record(package):
1) Seq# - added by kinesis
2) Partition Key and Data Blob < 1mb> - both included by producer

Question 55. 
You have been hired as a Solutions Architect to advice a company on the various authentication/authorization mechanisms that AWS offers to authorize an API call within the Amazon API Gateway. The company would prefer a solution that offers built-in user management.

Which of the following solutions would you suggest as the best fit for the given use-case?

Use Amazon Cognito User Pools

2. on demand

don't know how much throughput you need so it adjusts the shards

partition act differently

Question 54.
A media agency stores its re-creatable assets on Amazon Simple Storage Service (Amazon S3) buckets. The assets are accessed by a large number of users for the first few days and the frequency of access falls down drastically after a week. Although the assets would be accessed occasionally after the first week, but they must continue to be immediately accessible when required. The cost of maintaining all the assets on Amazon S3 storage is turning out to be very expensive and the agency is looking at reducing costs as much as possible. 

As an AWS Certified Solutions Architect - Associate, can you suggest a way to lower the storage costs while fulfilling the business requirements?

Configure a lifecycle policy to transition the objects to Amazon S3 One Zone-Infrequent Access (S3 One Zone-IA) after 30 days

Question 51.
A retail company wants to rollout and test a blue-green deployment for its global application in the next 48 hours. Most of the customers use mobile phones which are prone to Domain Name System (DNS) caching. The company has only two days left for the annual Thanksgiving sale to commence.

As a Solutions Architect, which of the following options would you recommend to test the deployment on as many users as possible in the given time frame?

Use AWS Global Accelerator to distribute a portion of the traffic to a particular deployment

Blue/green deployment is a technique for releasing applications by shifting traffic between two identical environments running different versions of the application: "Blue" is the currently running version and "green" the new version. This type of deployment allows you to test features in the green environment wihtout impacting the currently running version of your application. When you're satisfied that the green version is working properly, you can gradually reroute the traffic from the old blue environment to the new green environment. Blue/green deployments can mitigate common  risks associated with deploying software, such as downtime and rollback capability.

Use AWS Global Accelerator to distribute a portion of traffic to a particular deployment

AWS Global Accelerator is a network layer service that directs traffic to optimal endpoints over the AWS global network, this improves the availability and performance of your internet applications. It provides two static anycast IP addresses that act as a fixed entry point to your application endpoints in a single or multiple AWS Regions, such as your Application Load Balancers, Network Load Balancers, Elastic IP addresses or Amazon EC2 instances, in a single or in multiple AWS regions.

AWS Global Accelerator uses endpoint weights to determine the proportion of traffic that is directed to endpoints in an endpoint group, and traffic dials to control the percentage of traffic that is directed to an endpoint group (an AWS region where your application is deployed).

While relying on the DNS service is a great option for blue/green deployments, it may not fit use-cases that require a fast and controlled transition of the traffic. Some client devices and internet resolvers cache DNS answers for long periods; the DNS feature improves the efficiency of the DNS service as it reduces the DNS traffic across the Internet, and serves as a resiliency technique by preventing authoritative name-server overloads. The downside of this in blue/green deployments is that you don't know how long it will take before all of your users receive updated IP addresses when you update a record, change your ourting preference or when there is an application failure.

With AWS Global Accelerator, you can shift traffic gradually or all at once between the blue and the green environment, and vice-versa without being subject to DNS caching on client devices and internet resolvers, traffic fials and endpoint weights changes are effective within seconds.

Resiliency is the ability of a workload to recover to recover from infrastructure, service, disruptions, such as misconfigurations or transient network issues.

Disaster recovery (DR) is an important part of your resiliency strategy and concerns how your workload responds when a disster strikes (an event that causes a serious negative impact on your business). this response must be based on your organization's business objectives which specify your workloads in the cloud to meet your recovery objectives (RPO and RTO) for a given one-time disaster event. This approach helps your organization to maintain business continuity as part of BCP (Business Continuity Planning).

Resiliency = Disaster Recovery + Availability

Disaster Recover = RTO + RPO

Availability = MTBF + MTTR

MTBF = Mean Time Between Failures
MTTR = Mean Time To Recover

SLA - AWS Server Level Agreements

AWS Global Cloud Infrastructure - built with availaibility zones

AWS Auto Scaling

Responsibility for resilience 'in' the cloud:
continuous testing of critical infrastructure, workload architecture, change managment and operational resilience, observability and failure management

Responsibility for resilience 'of' the cloud:
hardware and services, computer, storage, database, networking. AWS infrastructure regions, availability zones, edge locations

BCP - Business Continuity Plan

AWS services

EBS snapshot
DynamoDB backup
RDS snapshot
Aurora DB snapshot
EFS backup
Redshift snapshot
Neptune snapshot
DocumentDB
FSx for Windows File Server, Amazon FSx for Lustre, Amazon FSx for NetApp ONTOP, and Amazon FSx for OpenZFS

S3, you can use S3 Cross-Region Replication (CRR) to asynchronously copy objects to an S3 bucket in the DR region continuously, while providing versioning for the stored objects so that you can choose your restoration point. Continuous replication of data has the advantage of being the shortest time (near zero) to bak up data, but may not protect against disaster events such as data corruption or maliciaons

AWS Backup supports copying backups across Regions, such as to disaster recovery Region.

As an additional disaster recovery strategy for your S3 data, enable S3 object versioning. Object versioning protects your data in S3 from the consequences of deletion or modivication actions by retianing the original version before the actio. Object versioning can be useful mitigation for human-error type disasters. If you are using S3 replication to back up data to your DR region, then, by default, when an object is deleted in the source bucket, S3 adds a delete marker in the source bucket only. This approach protects data in the /dr region from malicious deletions in the source Region.

Question 49.
An IT company has built a custom data warehousing solution for a retail organization by using Amazon Redshift. As part of the cost optimizations, the company wants to move any historical data (any data older than a year) into Amazon S3, as the daily analytical reports consume data for just the last one year. however the analysts want to retain the ability to cross-reference this historical data along with the daily reports.

The company wants to develop a solution with the Least amount of effort and Minimum cost. As a solutions architect, which option would you recommend to faciliate this use-case?

Use Amazon Redshift Spectrum to create Amazon Redshift cluster tables pointing to the underlyi8ng historical data in Amazon S3. The analytics team can then query this historical data to cross-reference with the daily reports from Redshift. 

Question 45
An IT company provides Amazon Simple Storage Service (Amazon S3) bucket access to specific users within the same account for completing project specific work. With changing business requirements, cross-account S3 access requests are also growing every mopnth. Thje comapnyu is looking for a solution that can offer user level as well account-level access permissions for the data stored in Amazon S3 bukcets. As a Solutions Architect, which of the following would you suggest as the MOST optimized way of controlling access for this use-case?

Use Amazon S3 Bucket Policies

Question 44.
An e-commerce application uses an Amazon Aurora Multi-AZ deployment for its database. While analyzing the performance metrics, the engineering team has found that the database reads are causing high input/output (I/O) and adding latency to the write requests against the database. As an AWS Certified Solutions Architect Associate, what would you recommend to separate the read requests from the write requests?

Set up a read replica and modify the application to use the appropriate endpoint

Question 42.
A financial services company has deployed its flagship application on Amazon EC2 instances. Since the application handles sensitive customer data, the security team at the company wants to ensure that any third-party Secure Sockets Layer certificate (SSL certifivate) SSL/Transport Layer Security (TLS) certificates configured on Amazon EC2 instances via the AWS Certificate Manager (ACM) are renewed before their expiry date. The company has hired you as an AWS Certified Solutions Architect Associate to build a solution that notifies the secuirty team 30 days before the certifivate expiration. The solution should require the least amount of scripting and maintenance effort.

Leverage AWS Config managed rule to check if any third-party SSL/TLS certifivates imported into ACM are marked for expiration within 30 days. Configure the rule to trigger an Amazon SNS notification to the security team if any certificate expires within 30 days

Question 40.
A company has hired you as an AWS Certified Solutions Architect - Associate to help with redesigning a real-time data processor. The company wants to build custom applications that process and analyze the streaming data for its specialized needs.

Which solution will you recommend to address this use-case?

Use Amazon Kinesis Data Streams to process the data streams as well decouple the producers and consumers for the real-time data processor

Question 37.
Your company is deploying a website running on AWS Elastic Beanstalk. The website takes over 45 minutes for the installation and contains both static as well as dynamic files that must be generated during the installation process.

As a Solutions Architect, you would like to bring the time to create a new instance in your AWS Elastic Beanstalk deployment to be less than 2 minutes. Whuich the following options should be combined to build a solution for this requirement?

Create a Golden Amazon Machine Image (AMI) with the static installation components already setup

Use Amazon EC2 user data to customize the dynamic installation parts at boot time

Question 36.
A company has grown from a small startup to an enterprise employing over 1000 people. As the team size has grown, the company has recnetly observed some strange behavior, with Amazon S3 buckets settings being changed regularly. How can you figure out what's happening without restircting the rights of the users?

Enable CloudTrail analyze tool

Question 35. 
An Elastic Load Balancer has marked all the Amazon EC2 instances in the target group as unhealthy. Surprisingly, when a developer enters the IP address of the Amazon EC2 instances in the web browser, he can acxcess the website. What could be the reason the instances are being marked as unhealthy?

The route for the health check is misconfigured

The security group of the Amazon EC2 instance does not allow for traffic from the security group of the Application Load Balancer

Question 14.
A leading online gaming company is migrating its flagship application to AWS Cloud for delivering its onlines games to users across the world. The company would like to use a Network Load Balancer to handle millions of requests per second. The engineering team has provisioned multiple instances in a public subnet and specified these instances IDs as the targets for the NLB.

As a solutions architect, can you help the engineering team understand the correct routing mechanism for these target instances?

Traffic is routed to instqances using the pirmary pirvate IP ADDRESS SPECIFIED IN THE PRIMARY NETWORK INTERFACE FOR THE INSTANCE

TutorialDojo Mock Exam Overview

A company needs to implement a solution that will process real-time streaming data of its data of its users across the globe. This will enable them to track and analyze globally-0distributed user activitiy on their website and mobile applications, including clickstream analysis. The solution should process the data in close geographical proximity to their users and respond to user requests at low latencies.

Which of the following is the most suitable solution for this scenario?

Integrate CloudFront with Lambda@Edge in order to process the data in close geographical proximity to users and respond to user reuqests at low latencies. Process real-time streaming data using Kinesis and durbleyt store the restuls to an Amazon S3 bucket.

Lambda@Edge is a feature of Amazon CloudFront that lets you run code to users of your application, which improves performance and reduces latency. With Lambda@Edge, you don't have to provision or manage infrastructure in multiple locatioins arouind the world. You pay only for the compute time you consume -there is no charge when your code is not running.

With Lambda@Edge, you can enrich your web applications by making them globally distributed and improving their performance - all with zero server administration. Lambda@Edge runs your cod in response to event generated by the Amazon CloudFront content delivery network (CDN). Just upload your code to AWS Lambda, which takes care of everything required to run and scale your code with high availability at an AWS location clopsest to your end user.

A company has a web application hosted in AWS cloud where the application logs are sent to Amazon CloudWatch. Laztely, the web application has been encounting some errors which can be resolved simply by restarting the instance.

What will you do to automatically restart the EC2 instance whenever the same application error occurs?

First, look at the existing CloudWatchir logs for keywords related to the application error to create a custom metric. Then, Create a ClouidWatch alarm for that custom metric which invokes an action to restart the EC2 instance.

VPC Flow Logs are for VPC

A company intends to give each of it6s developers a personal AWS account through AWS Organizations. To enforcew redgulatory policies, preconfigured WS Congig rules will be set in the new accounts.  A lolutions architect must see to it that devleopers azre unable to remove or modify any rules in AWS Config.

Which solution meets the objective with the least operational overhead?

Add the devloepers AWS account to an OU9. Attach a service control policy SCP to the OU that restrics access to AWS config

SCP is great for denying

A healthcare company manages patient data using a deistributed system. The organiaztion utilizes a microservice-based serverless application to handle various aspects of patient care. Data has to be retrieved and wrtieen from mulitp amaozn dynamoDB tables.

The primary gola is to enalbe efficient retrieval and writing of datga without impacting the baseline performance of the application as well as ensuring seamless access to patient information for healthcazare professionals.

Which of the following is the MOST OPERATIONALLY EFFIOCIENT SLOUIONT?>

Utilize AWS AppSync pipeline resolvers

AppSync pipeline resolverfs offer an elegant server side solution to address the common challenge faced iun web applications-aggregating data from multiple db tables. ZInstead of invoking multiple api calls across different dats sources, which ccan degarde appolication perfoamcne and user expeirience, appsync pipline resolvers enable easy erretrieval of data from mulitple sources with ujust a single call. By leveraging Pipeline functi8ons, these resolvers streamline the process of conoslidating and presenting data to end-users.

A healthcare company manages patient data using a distributed system.

The primary goal is to enable efficient retrieval and writing of data without impacting the baseline performance of application as well as ensruing seamlesas access to patient information for healtcazre professionals.

A DevOps Engineer is required to design a cloud ar4chitecture in AWS. The Engineeer is planning to develope a highly availbale and fault-tolerant architecture consisting of ELB and ASGH of EC2 instances dep;loyed across multiple Availability Zones. The will be used by an online account application that requires path-0based routing, host-based routing,. and bi-directional streaming using REemote Produde Call.

A solutions architect is managing an apoplication that runs on a Windows EC2 instance with an attached Amazon FSx for Windows File Server. To save cost, management has decided to stop the instance during off-hours and restart it only when needed. It has been observed taht the application takes several minutes to become fully operational which impacts productivity.

How can the solutions architect speed up the instance's loading time without driving the cost up?

Migrate the application to an EC2 instance with hibernation enabled

Can't enable after launch, it's why you must migrate to an EC2 with hibernation enabled

To save costs, your manager instructure you to analyze and review the setup of you AWS cloud infrastructure. you should also provide jan estimate of hos much your company will pay you for all tof the AWS resources that yhey are using.

A global news network created a CloudFront distribution for their web application. However, you noticed that the application's origin server is being hit for each request instead of the AWS Edge locations, which serve the cached objects. The issue oc curs even for the commonly requested objects.

What couild be a possible cause of this issue?

Cache memory age at zero causes every request a miss and call to primary server

A solutions architect is tasked with designing a scalable infrastructure solution for a business that runs uses Amazon Elastic Kubernetes Service (Amazon EKS) to execute container applications. Since the company's workload varies throughout the day, they want to make sure that its underlying infrastructure automatically scales in and out in response to demand.

Which of the following would meet the requirements with the LEAST amount of operational overhead?

Use a combination of Kubernetes Metrics and Kubernetes Cluster Autoscaler to manage the number of nodes

A company has a cloud architecture composed of Linux and Windows Amazon EC2 instances that process high volumes of financial data 24 hours a day, 7 days a week. To ensure high availability of the systems, the Solutions ARchitect must create a solution that enables monitoring of memory and disk utilization metrics for all instaces.

Which of the following is the most suitable monitoring solution to implement?

36. 
An animation comp;any conducts storyboard experiments usiung a Linux=based rendering engine and an editing application running on Windows. The rendering engine saves its output on a Network Fil System (NFS) share, while the editing application uses a Server Message Block (SMB) file system.

To share files betgween these applications, the comapny synchronizes data across the file systems. This method doubles their storage needs and causes difficulty in data management. The company wants to migrate ints environment to AWS to solve these issues.

How can the company meet the requirements with the least ABOUT OF CHANGES?

A company is storing financial reports and regulatory documents in an Amazon S3 bucket. To co9mply with the IT audit, they tasked their Solutions ARchitect to track all new objects added to the bucket as well as the removed ones. It should also track whether a versioned object is permanently deleted. The Architect must configure Amazon S3 to pulbic notifivations for these events to a queu for post-processing and to an Amazon SNS topic that will notify the Operations team.

Which of the following is the MOST suitale solution that the ARchitect should implement?

Create a new Amazon SNS topic and Amazon SQS queue. Add an S3 event notification configuration on the bucket to pulish s3:PObjectCreated and s3:OjbectRemoved:Delete event types of SQS and SNS.

A company needs to implement a solution that will process real-time streaming data of its users across the globe. This will enable them to track and analyze globally-distributed user activity on their website and mobilew applications, including clickst4ream analysis. The solution should process the data in close geographical proximity to their users and respond to user requests at low latencies.

Which of the folloing is the most suitable sdolution in this scenario?

Integrate CloudFront with Lambdfa@Edge in order to process the data in close geographical proximity top users and respond to user requests at low latencies. Process real-time streaming data using Kinesis and durably store the results to an Amazon S3 bucket.

A healthcare company manages patient data using a distributed system. The organization utilizes a microservice-based serverless application to handle various aspects of patient care. Data has to be retrieved and written from multiple Amazon DynamoDB tables.

The primary goal is to enable efficient retrieval and writing of data without impacting the baseline performance of the application as well as ensuring seameless access to patient information for healthcare professionals.

Which of the following is the MOST operationally efficient solution?

Utilize AWS AppSync pipeline resolvers

AppSync pipeline resolvers offer an elegant server-side solution to address the common challenged faced in web applications-aggregate data from multiple database table4s. Inste4ad of invoking multiple API calls across different data sources, which can degrade application performance and user experience, AppSync pipeline resolvers enable easy retrival of data from  multiple sources with just a single call. By leveraging Pipeline functions, these resolvers streamline the process of conoslidating and presenting data to end-users.

AWS AppSync is a managed servgfice that makes it easy to build scalable APIs tahts connect5 applications to data./ Developers use AppSync every day to build GraphQL API that interact with data sources like Amazon DynamoDB AWS Laambada, and HJTTP APIs. With AppSync, developers can write their resolvers using JavaScript, and run their code on AppSync's APPSYNC_JS runtime

A data center equipped with several physical servers is connected to AWS via a 10 Gbps AWS Direct Connect link. A solutions architect is tasked with rehosting all on-premises applicatins, data, and operating systems to AWS. Interruptions to business operations must be minimized as well.

Which solution meets the requirement?

Create a replication task using AWS Transform MGN

A multinational corporation is expanding its operations and needs to efficiently monitor and analyze IAM-related erros, specifically Access Denied and Unauthorized error sin their AWS accounts. The company has AWS CloudTrail enabled for logging purposes.

Query with AWS CloudTrail Lake to find specific errors in CloudTrail logs.

A compnay is revamping its existing stateless inventory management system. The application is depoloyed acdr5oss 7 EC2 instance sin multiple avaliability zones behind an application load balancer (ALB). The application is designed to handle varying traffic patrterns. Still, engineers have observed taht treaffic is consistentlyh routed to a single Ec2 instacne, resulting in performance bottlenecks and higher latency for sopme reaosn.

What is the most effective solution to resolve the underlying load balancing issue?

A startup wants to imrpove service availability and fault tolerance by distgributing inc omingb traffic across multiple servers. The company uses Auto scalikng Group (ASG) of Amazon Ec2 instance sin the us-east

An accounting application uses an Amazon RDS database configured with RDS Multi-AZ to improve availabiltiy. What would happen to RDS if the primary database instance fails?

The canonical name record (CNAME) is swtiched from the primary to standby instance

A DevOps Engineer is required to design a cloud architecture in AWS. The Engineer is planning to develop a highly available and fault-tolerant architecture consisting of an Elastic Load Balancer and an Auto Scaling group of EC2 instance sdeployed across multiple Availabiltiy Zones. This will be used by an online accounting application that requires path-based routing, host-based routing, and bi-directional; streaming using Remote Procedue Call (gRPC). 

Which configuration will satisfy the given requirement?

A company has multiple VPCs with IPv6 enabled for its suite of web applications. Thje Solutions ARchitect attempted to deploy a new Amazon EC2 instance but encountered an error indicating that there were no availabie IP addresses on the subnet. The VPC has a comination of IPv4 and IPv6 CIDR blocks, but the IpV4 cidr blocks are nearing exhaustion. The architect needs a solution that will resolve this issue while allowing futre scalability.

How should the Solutions ARchitect resolve this problem?

A healthcare company has developed an AWS Lambda function to handle requests from a third-party analytics service. When new patient dat is available, the servic3 send aqn HTTP POST request to a webhook intendted to trfgigger the Lambda function.

What would be the MOST operationally efficient solution to ensure that the service can ccall the Lambda fun ctioni'?

Generate a Lambda Functiuon URL and use it as the webhook for the third-party analytics service.

A digital bank has recently deployed a fraud detection model in AWS Lambda. The company intends to put the model to test by processing transactions that are recorded in the production DynamoDB table. The security team must be immediately notified when a transaction is flagged as fraudulent.

How can the solutions architect satisfy the requirements while minimizing the iumpact on database operations and performance?

8/4/26
Both historical records and requently accessed data are stored on an on-premise storage system. The amount of current data is growing at an exponential rate. As the storage's capacity is nearing its limit, the company's Solutions Architect has decided to move the historical records to AWS to free up space for the active date.

Which of the following architectures deliver the best solution in terms of cost and operational management?

Use AWS DataSync to move the historical records from on-premises to AWS. Choose Amazon S3 Glacier Deep Archive to be the destgination for the data. 
This is because it being on-premise, you are able to go straight into Glacier.

In Amazon EC2, you can manage your instances from the moment you launch them up to their termination. You can flexibly control your computing costs by changing the EC2 instance state.

Which of the following statements is true regarding EC2 billing?

When preparing hibernation in stop status

When RI stop you still get billed.

A company has established a dedicated network connection from its on-premise data center to AWS Cloud using AWS Direct Connect (DX). The core network services, such as the Domain Name System (DNS) service and Active Directory services, are all hosted on-premises. The company has new AWS accounts that will also require consistent and dedicated access to these network services.

Which of the following can satisfy this requirement with the LEAST amount of operational overhead and in a cost-effective manner?

Create a new Direct Connect gateway and integrate it with the existing Direct Connect connection. Set up a Transit Gateway betweeen AWS acdcounts and associate it with the Direct Connect gateway.

An e-commerce company plans to optimize its disaster recovery configuration using AWS Cloud to minimize opertional disruptions during outages or major system maintenance for its on-premises Microsoft SQL Server-based application. The objective is to achieve a recoveryu point objective (RPO) of 60 seconds or less and recov ery time (RTO) of 1 hour

Set up a pilot light strategy using AWS Elastic Disaster Recovery (AWS DRS) to 
replicate the changes of the on-premises application to AWS.


An organiazation plans to run an application in a dedicated physical server that doesn't use virtualization. The application data will be sorted in a storage solution that uses an NFS protocol. To prevent data loss, you need to use a durable cloud storage service to store a copy of your data. Which of the following is the mopst suitable solution to meet requiremtn?

Storage Gateway physical appliance on premise on your compute resources. configure file gateway to store the application data and create an amazon S3 bucket to store a buackup of your data. 

Volume Gateway using iSCSI protocol

An organization plans to run an application in a dedicated physical server that doesn't use virtualizatiuon. The application data will be stored in a sotrage solution that6 uses an NFS protocl. To prevent data loss, you need to use a durable cloud storage service to stroe a dopy of your data. 

Which of the following is the most5 suitable solution to meet the requirement?

Use an AWS Storage Gateway hardware appliance for your compute resources. Configure File Gateway to store the application data and create an Amazon S3 bucket to store a backup of your data.

A company has a web-based ticketing service that utilizes Amazon SQS and a fleet of EC2 instances. The EC2 instances that consume messages from the SQS queue are configured to poll the queue as often as possible to keep end-to-end throughput as high as possible. The Solutions Architect noticed that polling the queue in tight loops is using unnecessary CPU cycles, resulting in increased operational costs due to empty responses.

In this scenario, what should the Solutions Architedct do to make the system more cost-effective?

A game development company operates several virtual reality (VR) and augmented reality (AR) games that use various RESTful web APIs hosted in its on-premises data center, which currently sits behind a content delivery network (CDN) for faster global delivery. Due to the unprecendented growth of the company, the management decided to migrate its system to AWS Cloud to scale out its resources as well as to minimize costs.

Which of the following is the mos t5ocst-effective and scalable solution to meet the above requirement?

Lambda and API

A company is using an Amazon RDS for MySQL 5/6 with Multi-AZ deployment enabled and several web servers across two AWS Regions. The database is currentlyh experiencing highly dynamic reads due to growth of the company's websxite. The Solutions Architect tried to test the read perfformanced from the secondary AWS Region and noticed a notable slowdown on the SWL queries.

Which of the following options would provide a read replication latency of less than 1 second?

Migrate the existing datbase to Amazon Aurora and create a cross-region read replica.

A Forex trading platform, which frequently processes and stores global financial data every minute, is hosted in an on-premises data center and uses an Oracle database. Due to recent cooling problem in its data center, the company urgenlty needs to migrate its infrastructure to AWS to improve the performance of its applications. As the Solutions Architect, the responsibility is to ensure that the databse is properly migrated and remains availabled in case of databse server failure in the future, folowwing AWS Prescriptive Guiidance for datbase migration and high availability.

Which combination of actions would meet the requirement?

Migrate & Multi-AZ

A company plans to host a web application in an Auto Scaling group of Amazon EC2 instances. The application will be used globally by users to upload and store several types of files. Based on user trends, files that are older than 2 years must be stored in a different storage class. The Solutions Architect of the company needs to create a cost-effective and scalable solution to store the old files yet still provdie durability and high availability.

Which of the following approach can be sued to fulfill this requirement?

A company needs to use Amazon Aurora as the Amazon RDS database engine for its web application. The Solutions Architect has been instructed to implement a 90-day RDS backup retention policy.

Which of the following options can satisfy the given requirement?

Create a AWS Backup plan to take daily snapshots with a retention of 90 days.

A company deployed an online enrollment system database on prestigious university, which is hosted in RDS. The Solutions Architect is required to monitor the database metrics in Amazon CloudWatch to ensure the availability of the enrollment system. What are the enhanced monitoring metrics that Amazon CloudWatch gathers from Amazon RDS DB instances which provide more accurate information?

Amazon RDS provides metrics in real-time for the operating system (OS) that your DB instance runs on. You can view the metrics for your DB instance using the console or consume the Enhanced Monitoring JSON output from CloudWatch Logs in a monitoring system of your choice.

CloudWatch gathers metrics about CPU utilization from the hypervisor for a DB instance, and Enhanced Monitoring gathers its metrics from an agent on the instance. As a result, you might find differences between the measurements because the hypervisor layer performs a small amount of work. The differences can be greater if your DB instances use smaller instance classes because than there are likely more virtual machines (VMs) that are managed by the hypervisor layer on a single physical instance. Enhanced Monitoring metrics are useful when you want to see how differnet processes or threads on a DB instance use the CPU.

CloudWatch Metrics for RDS = CPU, connections, storage, memory (hypervisor view)
Enhanced Monitoring = process-level detail, child processes, OS processes (agent view)

A company has an application that uses multiple EC2 instances located in various AWS regions such as US Eaast (Ohio), US West (N. Carolina), and EU (Ireland). The manager instructured the Solutions Architect to set up a latency-based routing to route incoming traffic for www.tutotialsdojo.com to all the EC2 instances accross all AWS regions.

Which of the following options can satisfy the given requirement?

An advertising company is currently working on a proof of concept project that automaitcally provides SEO analytics for its clients. Your company has a VPC in AWS that operates in a dual-stadck mode in which IPv4 and IPv6 is allowed. You deployed the application to an Auto Scaling group of EC2 instances jwith an Application Load Balancer in front that evenly bdistributes the incoming traffic. You are ready to go live but you need to point your domain name to the Application Load Balancer.

In Route  53, which record  types will you use to point the DNS name of the Application Load Balancer?

A record set
AAAA record set
CNAME can't create at the zone apex

A medical records company is planning to store sensitive clinical trial data in an Amazon S3 repository with the object-level versioning feature enabled.  The Solutions ARchitect is tasked with ensuring that no object can be overwritten or deleted by any user for a period of one year only. To meet the strict compliance requirements, the root user of the company's AWS account must also be restricted fromi making any changes to an object in the S3 bucket. Backup Vault Lock offers similar immutability, but the company requrires object-level protection in S3.

Which of the following is the most secure way of storing the data in S3?

Enable S3 Object Lock in compliance mode with a retention period of one year

A Solutions Architect is designing a monitoring application which generates audit logs of all operational activities of the company's cloud infrastructure. Their IT Security and Compliance team mandates that the application retain the logs for 5 years before the data can be deleted.

How can the Architect meet the above requirement?

A multinational bank is storing its confidential files in an S3 bucket. The security team recently performed an audit, and the report shows that multiple files have been uplaoded without 256-bit Advanced Encryption Standard (AES) server-side encryption. For added protection, the encryption key must be automatically rotated every year. The solutions architect must ensure that there would be no other unencryupted files uploaded in the S3 bucket in the future. 

Which of the following meet these requiremets with the LEAST operational overhead?

A media company needs to configure an Amazon S3 bucket to serve static assets for the public-facing web application. Which methods ensure that all of the objects uploaded to the S3 bucket can be read publicly all over the internet?

recount ontap vs other FSx file system services

NFSv4 protocol? look into protocols

IAM policy to enforce start, stop, and terminate EC2 instances IN us-west-1 region

also

any requests originating outside of the company's network range should be denied
192.158.1.0/24

###
What's EC2 Nitro System?

CloudFormation: read some
What does IRSA  IAM Role for Service Accounts means?

What's the difference between HPA Horizontal Pod Autoscaler vs Cluster Autoscaler
Horizontal Pod Autoscaler - automatically adds/removes pods based on CPU, memory, or custom metrics. Needs Kubernetes Metrics Server to collect those metrics.

# kubernetes metrics and not cloudwatch for eks?

Vertical Pod Autoscaler - adjusts how much CPU/memory each pod gets

Cluster Autoscaler, AWS's orignal tool for add/removing EC2 nodes when pods can't be scheduled. Works but slower.

# what does it mean when pods can't be scheduled?

Karpenter - AWS's newer, faster node scaling tool. Provisions nodes in seconds not minutes. Less operational overhead than Cluster Autoscaler. 

# is there a use case for Karpenter over Cluster Autoscaler?





planning to use DX connection to establish a dedicated connection

multiple research departments in AWS cloud

each department is free to provision resources as needed but to ewnsure normal operations, 

TRACK aws resources usage so it doesnt reach quotas

bombination of two choice

A financial services company plans to migrate its trading application from on-premises Microsoft Windows Server to Amazon Web Services (AWS). The solution must ensure high availability across multiple Availability Zones and offer low-latency access to block storage.

Which of the following solutions will fulfill these requirements?

Configure the trading application on Amazon EC2 Windows Server instances across two Availability Zones. Use Amazon FSx for NetApp ONTAP to create a Multi-AZ file system and access the data via iSCI protocol.

iSCI protocol is block format

A company has several EC2 Reserved Instances in their account that need to be decommissioned and shut down since they are no longer used by the development team. However, the data is still required by the audit team for compliance purposes.

Which of the following steps can be taken in this scenerio?

sell them
save the ebs snapshots and terminate the EC2 instances

An organization uses a Microsoft SQL Server database to support its suit of applications. The organiazation plans to transition to an Amazon Aurora PostgreSQL database while minimizing application code modifications. 

Which combination of actions will achieve these objecttives?

Turn on Babelfish on Aurora PostgreSQL to allow applications to continue using existing SQL queries

Schema Tool

A company installed sensors to track the number of people who visit the park. The data is sent every day to an Amazon Kinesis strream with default settings for processing, in which a consumer is configured to process the data every other day. The employee noticed that the Amazon S3 bucket is not receiving all of the data that is being sent to the Kinesis stream. The employee checked the sensors to see if its properly sending the data to Kinsesis and verified that the data is indeed sent every day.

What could be the reaosn for this?

By default, the data records are only accesible for 24 hours from the time they are added to Kinesis stream. 

A data analytics company, which uses machine learning to collect and analyze consumer data, is using Redshift cluster as their data warehouse. You are instructured to implement a disaster recovery plan for their systems to ensure business continuity even in the event of an AWS region outage.

Which of the following is the best approach to meet this requirement?

Enabled Cross-Region Snapshots Copy in your Amazon Redshift Cluster
this is also can be made autonomously 

Amazon Elastic Kubernetes Service (Amazon EKS) with IAM Role for Service Accounts (IRSA) is used by an e-commerce company to deploy and manage its containerized applications. The website experien ces a surge in traffic around the holidays, which significantly adds to the effort. The goal is to ensure that its underlying infrastructure automaitcally scales in and out in response to demand.

Which of the following would meet the requirements with the LEAST amount of operational overhead?

Install the Kubernetes Metrics Server on the EKS cluster and activate the Horizontal Pod Autoscaling.

Set up Karpenter to automatically adjust the number of nodes in the EKS cluster when pods fail or are rescheduled onto other nodes.

Fundamentally, I must learn Kubernetes and in particular how EKS (Elastic Kubernetes Service) works to get this answer correct.

A client is hosting their company website on a cluster of web servers that are behind a public-facing Application Load Balancer (AWS ALB). The client also uses Amazon Route 53 to manage their public DNS.

How should the client configure the DNS zone apex record to point to the laod balancer?

Create an A record aliased to the load balancer DNS name.

An e-commerce company is redesigning the architecture of its application. The new architecture needs a more robust application layer and an online transactional processing (OLTP) relational database that can handle spiky traffic loads. The company also wants to ensure the application is always available while minimizing computing costs during idle periods.

As the company's solution architect, which solution would be the most cost-effective to meet these requirements?

A company uses multiple AWS acounts consolidated under AWS Organizations. The company needs to copy multiple Amazon S3 objects to an S3 bucket in a different owned AWS account. The Solutions Architect must configure permissions to enable this transfer while ensring the destination account owns the copied objects rather than the source account.
How can the Architect accoplish this requiremehnt

A hospital has a mission-critical application that uses a RESTful API powered by Amazon API Gateway and AWS Lambda. The medical officers upload PDF reports to the system which are then stored as static media content in an Amazon S3 bucket. 

The security team wants to imporve its visibility when it comes to cyber-attacks and ensure HIPAA (Health Insurance Portability and Accountability Act) compliance. The company is searching for a solution that continuously monitors object-level S3 API operations and identifies protected health information (PHI) in the reports, with minimal changes in the existing Lambda function.

Which of the following solutions will meet these requirements with the LEAST operational overhead?

A startup plans to scale out its cloud resources. With its rapid growth, the company needs an automated way of scanning its Amazon EC2 instances for security purposes. The company needs to automatically discover software vulnerabilities on its cloud resources and validate that its workloads meet security compliances.

Which of the following options should be implemented to meet the company requirements?

Amazon Inspector to publish results to Amazon EventBridge (Amazon CloudWatch Events) and send notifications using Amazon Simple Notification Service (Amazon SNS)

Amazon Inspector is a vulnerability management service that continuosusly scans your AWS workloads for vulnerabilities. Amazon Inspector automatically discovers and scans Amazon EC2 instances and container imnages residing in Amazon Elastic Container Registry (Amazon ECR) for software vulnerabilties and unintented network exposure.

When a software vulenerability or network issue is discovered, Amazon Inspector creates a finding describes the vulnerability, indentifies the affected resource, rates the severity of the vulnerability, and provides remediation guidance.

Friendly reminder: GuardDuty is for malicious activity and it is a threat detection service that continuously monitors your AWS workloads 

A healthcare company has migrated its Electornic Health Record (EHR) system to AWS and is now seeking to protect its production VPC from a wide range of potential threats. The company requires a solution to monitor both incoming and outgoing VPC traffic and block any malicioius connections.

As a Solution Architect, how will you meet these requirements?

Create custom security rules in AWS Network Firewall to detect and filter traffic passing to and from the production VPC

AWS Network Firewall is a managed service offering advanced network security capabilities to protect VPCs (Virtual Private Clouds) against potential threats. It enables you to define custome security rules and policies to monitor and control the traffic flow passinug to and from your VPC. With AWS Network Firewall, you can create highly customizablew rules based on various criteria, such as IP addresses, domains, ports, and protocols. These rules allow you to precisely detect and filter incoming outgoing traffic, enabling you to identify and block any malicious connections.

In the given scenario, the company can monitor incoming and outgoing VPC traffic by implementing custom security rules in AWS Network Firewall. The rules can be tailored to detect suspicious or malicious connections that could compromise the security of the EHR system or put sensitive patient data at risk. The granular approach ensures that the healthcare company can enforce a strict security posture and mitigate the risk of unauthorized access or data breaches.

A multimedia company needs to deploy web services to an AWS region that they never used before. The company currently has an IAM role for its Amazon EC2 instance that permits the instance to access Amazon DynamoDB. They want their EC2 instances in the new region to have the exact same prvileges.

What should be done to accomplish this?

Company has:
regional API Gateway (us-east-2) that servers as a proxy to a backened service
has a hosted zone for its domain on Amazon Route 53

clients connect to the service using the invoke URL of the api stage. 

We want custom domain name with the API.
The domain name must support HTTPS


company has a datacenter with  several applictions hosted on hurded of VM running

company wants to take advantage of 
SCALABILITY and cost effeectiveness


migrate app to cloud.
before starting the migration, managent wants to have an inventory of all th4e servers and watns the ab9ility to track the miogration of each applicatiuon

A company is running a batch job on an EC2 instance inside a private subnet

ALB - Ec2 instances for web application + auto scaling group behind ALB

ASG

A manufacturing company is building an IoT-based system to detect faults in its proudction process in real-time. 
real-time

the system will feed sensor data to API Gateway REST API, where the dat will be analyzed for any anomalies for faults

the resulf ot the processing will then determine remedial action to be taken.  it's critical that the data is process in the sxequence in chi

8/9/26

What is a Service Quota?

AWS limits how much of each serivce you can use. Examples;

    Maximum 5 VPC per region
    Maximum 20 EC2 per region
    Maximum 100 S3 bvuckets per accouunt

These are service quotas - hard limits AWS enforces

The proglem:

Multiple departments freely provioning resources. Nobody is tracking how lcose they are to hitting these limits

One day - someone tries to create a 6th VPC and it fails. Unexpected outage. BAd.

The goal:

Get warned before you hit the limit. Not after.

How do you track service quotas in AWS?
AWS trusted advisor has a feature called service limits check

AWS Trusted Adviusor has a feature called Service Limits Check

It looks at your current usage vs your quota limits and says:
"Hey, you're at 80% of your EC2 limit in us-east-1. You might want to request an increase"

How do automate this for 24 hours?

Lambda functiuon runs every 24 hours
Calls DescribeTrustedAdvisorChecks API
Gets current service limit status
If approaching likmit > send SNS notification > team gets alerted

A company has multiple research departments that have deployed several resources to the AWS cloud. Each department is free to provision resrouces as needed. To ensure normal operations, the coimpany wants to track its AWS resources usage so that6 it does not reach the AWS service quotas unexpectedly.

Which combination of actions should the Solutions Architect implement to meet the company requirements?

Write an AWS Lambda function that refreshes the AWS TRusted QAvisor Serive Limits checks and set it to run every 24 hours.

Capture the events using Amazon EventBridge (Amazon CloudWatch Events) and use an Amazon Simple Notification Service (Amazon SNS) topic as the target for notifications.

A company has a web-based ticketing service that utilizes Amazon SQS and a fleet of EC2 instances. The EC2 instances that consume messages from the SQS queue are configured to poll the queue as often as possible to keep end-to-end throughput as high as possible. The Solutions Architect noticed that polling the queue in tight loops is using unnecessary CPU cycles, resulting in increased operational costs due to empty responses.

In this scenario, what should the Solutions Architect do to make the system more cost-effective?

(view)	1	0	1	00:00:00	
 Configure Amazon SQS to use long polling by setting the ReceiveMessageWaitTimeSeconds to zero.
 Configure Amazon SQS to use long polling by setting the ReceiveMessageWaitTimeSeconds to a number greater than zero.
 Configure Amazon SQS to use short polling by setting the ReceiveMessageWaitTimeSeconds to a number greater than zero.
 Configure Amazon SQS to use short polling by setting the ReceiveMessageWaitTimeSeconds to zero.
In this scenario, the application is deployed in a fleet of EC2 instances that are polling messages from a single SQS queue. Amazon SQS uses short polling by default, querying only a subset of the servers (based on a weighted random distribution) to determine whether any messages are available for inclusion in the response. Short polling works for scenarios that require higher throughput. However, you can also configure the queue to use Long polling instead, to reduce cost.

The ReceiveMessageWaitTimeSeconds is the queue attribute that determines whether you are using Short or Long polling. By default, its value is zero which means it is using Short polling. If it is set to a value greater than zero, then it is Long polling.

Hence, configuring Amazon SQS to use long polling by setting the ReceiveMessageWaitTimeSeconds to a number greater than zero is the correct answer.

Quick facts about SQS Long Polling:

- Long polling helps reduce your cost of using Amazon SQS by reducing the number of empty responses when there are no messages available to return in reply to a ReceiveMessage request sent to an Amazon SQS queue and eliminating false empty responses when messages are available in the queue but aren't included in the response.

- Long polling reduces the number of empty responses by allowing Amazon SQS to wait until a message is available in the queue before sending a response. Unless the connection times out, the response to the ReceiveMessage request contains at least one of the available messages, up to the maximum number of messages specified in the ReceiveMessage action.

- Long polling eliminates false empty responses by querying all (rather than a limited number) of the servers. Long polling returns messages as soon any message becomes available.


A company is implementing its Business Continuity Plan. As p0art of this initiative, the IT Director instructed the IT team to set up an automated backup of all the Amaon EBS volumes attached to the company's Amaon EC2 instances. The solution muhst be implemented as soon as possib le and should be both cost-effective and simple to maintain.

Whbat is the fastest and most cost-effective solution to automatically back up all of the EBS volumes?

Use Amazoln Data Lifecycle Manager (Amazon DLM) t4o auotmate the creation of EBS snapshots.

A retail website has intermittent, sporadic, and unpredictable transactional workloads throughout the day that are hard to predict. The website is currently hosted on-premises and is slated to be migrated to AWS. A new relational database is needed that autoscales capacity to meet the needs of the application’s peak load and scales back down when the surge of activity is over.

Which of the following option is the MOST cost-effective and suitable database setup in this scenario?

Launch an Amazon Aurora Serverless DB cluster then set the minimum and maximum capacity for the cluster.

Launch an Amazon Aurora Provisioned DB cluster with burstable performance DB instance class types.

Launch an Amazon Redshift data warehouse cluster with Concurrency Scaling.

Launch a DynamoDB Global table with Auto Scaling enabled.

The Problem:
Company has 20 AWS accounts. Each account has security groups. Security groups have CIDR rules like:
    Allow: 192.168.1.0/24 (new york office) 
    Allow: 10.0.0.0/16 (london office)

New office opens in Tokyo > need to add its CIDR to every security group in every account
Old office closes > need to remove the CIDR from every securityh group in every account
doing this manually = nightmare. 20 accounts x multiple security groups each = hundreds of updates

The fix:
What is a Prefix List?
instead of putting CIDRs directly in security groups, you put them in prefix list. Then security groups reference the prefix list ID.

"The maximum number of entries for the prefix lists counts against the quota for entries for the resource."

### Category: CSAA - Design Resilient Architectures

A company hosts its web application on a set of Amnazon EC2 instances in an Auto Scaling group bgehind an Application Load Balancer (ALB). The application has an embedded NoSQL database. As the application receives more traffic, the application becomes overloaded maiunly due toi database requests. The managmenet wants to ensure that the database is eventually consitstent and highly availbalbe.

Which of the following options can meet the company requirements with the least operational overhead?

Configure the Auto Scaling group to spread the EC2 instances across three Availability Zones. Use the AWS Database Migration Service (AWS DMS) with a replication server and an ongoing replication task to migrate the emebedded NoSQL database to Amazon DynamoDB.

An online registration system hosted in an Amazon EKS cluster stores data to a db.t4g.medium Amazon Aurora DB cluster. The database performs well during regular hours but is unable to handle the traffic surge that occurs during flash sales. A solutions architect must move the database to Aurroa Serverless while minimizing downtime and the impact on the operation of the application.

Which change should be taken to meet the objective?

Use AWS Database Migration Service (AWS DMS) to migrate to a new Aurora Serveless database

A tech startup is launching an on-demand food delivery platform using an Amazon ECS cluster with an AWS Fargate serverless compute engine and Amazon Aurora. It is expected that the database read queries will significantly increase in the coming weeks. A Solutions Architect recently launched two Read Replicas to the database cluster to improve the platform's scalability. The team considered using lazy loading to cache results, but that does not balance read traffic across replicas.

Which of the following is the MOST suitable configuration that the Architect should implement to load balance all of the incoming read requests equally to the two Read Replicas?

The Scene:
your company has 1200 employees. They already log into work computers using Active Directory (AD) - the standard Windows corportate login system.

You want those same employees to access S3 without creating 1200 separate AWS accounts.

You also want each employee to only see their own folder in S3

3 problems to solve:

1. how do employees use their existing corportate login to access AWS?
2. how do you issue AWS credentials without creating IAM users?
3. how do you restrict each person to only their folder?

1. SSO (single sign-on) with corporate AD:
you need a federation proxy or Identity Provider that sits between your corporate AD and AWS.

It says to AWS: "This person already authentitcated with out corporate system - trust me"

AWS trusts it because you've set it up as a trusted Identity Provider.


Problem 2 - Temporary AWS credentials
aws sts (security token service) issues temporary credentials to the federated user.

No permanent IAM user created. No long-lived access keys. Just a temporary token that expires.

Problem 3 - restrict to their own S3 folder
IAM policy uses a policy variable ${aws:username} to dynamically restrict access

Resource: "arn:aws:s3:::company-bucket/${aws:username}/*"

John logs in > only see company-bucket/john

Full Flow:
employee enters AD credentials 
>
federation proxy verifies with AD
>
AWS STS issues temporary credentials
> 
employee accesses S3
>
IAM policy restricts to their folder only

federation + STS
Iam role + policy for folder restriction

read endpoint for read operations, such as queries. this endpoint reduces the overhead on the primary instance

cluster endpoint for writes

A launch template is a template that an Auto Scaling group uses to launch EC2 instances. When you create a launch template, you specify information for the instances, such as the ID of the Amazon Machine Iamge (AMI), the instance type, a key pair, one or more security groups, and a block device mapping. If you've launched an EC2 instance before, you specified the same information in order to launch the instance.

You can specify your launch template with multiple Auto Scaling groups. However, you can only specify one launch template

For the MS SQL rule, change the source to the security group ID attached to the application tier

AWS IAM Identity Center centralizes access management for various AWS accounts and applications. It provides single sign-on access, enabling users to manage all their aasigned accounts from a single location. Users can synchronize with an existing identity provider to create new users and groups directly within the service.

IAM Identity Center utilizes permission sets - collections of IAM policies - to manage user access across AWS Organizations. It includes a user-frinedly AWS Access Porta for easy access to applications and supports deployment for both organization and account intances. Designed for high availability across multiple availability zones, the service ensures secure access through AWS Identity and Access Management (IAM) roles and policies.

S3 Glacier has three retrieval speeds:

Retrieval Type:     Speed:              Cost:
Expedited           1 - 5 minutes       Most expensive
Standard            3 - 5 hours         Medium
Bulk                5 - 12 hours        Cheapest

The problem with Expedited:
Expedited retrieval is fast BUT capacity is not guaranteed during high-demand periods.
If everyone needs data at once - you might not get capacity

Provisioned Capacity:

You can purchase provisioned retrieval capacity in advance. This guarantees Expedited retrieval is available whenever you need it.

Guarantees at least 3 expedited retrievals per 5 minutes
Supports up to 150 MB/s throughput

### Category:   CSAA - Design High-Performing Architectures

mobile application that collects votes for a singing competition

millions of users
around the world

submit using mobile phones

votes are collected and stored in a highly scalable and highly available database

queried for real-time ranking

db will undergo frequent schema changes throughout the time frame

needs to have read capacity units (RCU) that scale for live rankings

DynamoDB is fully managed, serverless, key-value NoSQL database designed to run high-performance at scale

built in security
automated multi-region replication, in-memory caching, and data import and export tools
DynamoDB tables are schemaless - other than the primary key, you do not need to define any extra attributes or data types when you create a table, which is why it's suitable for data with a frequently changing schema


IT consulting company have an application processes a large stream of financial data by ECS Cluster results go to a DynamoDB table.

detect new entries in DynamoDB table then Lambda function to run processing

What solution can be easily implemented to alert Lambda?

DynamoDB Streams is integrated with Lambda. It's minimal effort to enable Lambda to be triggered on an event


migrate
trading application from on-premise 
Microsfot Windows Server to AWS
ensure high availability across multiple Availability Zones
low-latency acess to block storage (iSCSI)

fufill requirements

EC2 Windows Server across two Availability Zones
use Amazon FSx for NetApp ONTAP to create a Multi-AZ file system and access the data via iSCI protocol


real-time monitoring app senses items and deducts from customer accounts
analyze items that are frequently being bought and store the results in S3 storage to determine the purchase behavior of its customers

capture, transform, and load streaming data into S3, Amazon OpenSearch Service, and Splunk

Amazon Data Firehose


startup needs file system for its .net web app on Ec2 Windows instance

high throughput and IOPS integrated with Microsoft Active Directory

MOST suitable service

Amazon FSx for Windows File Server

AWS Storage Gateway - File Gateway is incorrect. It can integreate with Windows and Mircosoft Active Directory

FSx has higher throughput and IOPS
providing hundreds of thousands (or even millions) of IOPS


microservices architecture, decoupled services

remove the need to provision and manage servers
application isolation by design

MOST suitable

Use AWS Fargate on Amazon EKS with Kubernetes Cluster Autoscaler to run the containerized banking platform

Fargate is a serverless compute engine for containers
Fargate removes provision and manage of servers
lets you specify and pay for resources per application
app isolation by design

The kubernetes cluster autosacler is well-known solution for cluster autoscaling
maintained by the SIG Autoscaling team. Its primary function is to ensure that your cluster has enough nodes to successfully schedule your pods without wasting resources. The Cluster Autosacler monitors for pods that are unable to schedule and itentifies underutitlized nodes. It then simulates the addition or removal of nodes before implementing any changes to your cluster


game development company operates several Virtual Reality (VR) and Augmented Reality (AR) games that use various RESTful web APIs hosted on-premises data center
sits behind content delivery network (CDN) for faster glocal delivery.

migrate to AWS 
cost-effective scalable solution

Use AWS Lambda and Amazon API Gateway


Route 53 instead of ELB to load balance the incoming request to the web app
two EC2 isntances to which EC2 instance distributed to
specific percentage of traffic to go to each instance

routing policy to use?

Weighted

Weighted routing lets you associate multiple resources with a single domain name or subdomain name and choose how much traffic is routed to each resource

useful for variety of purposes including load balancing and testing new versions of software

you can set a specific percentage of how much traffic will be allocated to the resourced by specifying the weights


app hosted in Auto Scaling group of EC2 instances
improve monitoring process, configure current capacity to increase or decrease based on a set of scaling adjustments

specify scaling metrics and threshold values for CloudWatch alarms that trigger the scaling process

most suitable type of scaling policy

step scaling lets you choose scaling metrics and threshold values for the ClouidWatch alarms trigger scaling process as well as define how your scalable target should be scaled when a threshold is in breach for a specified number of evalutation periods.

EC2 Auto Scaling supports the following types of scaling policies:
    Target tracking scaling - increase or decrease the current capacity of the group based on a target value of a specific metric. This is similar to the way thqat your thermostat maintains the temperature of your home - you select a temperature and the thermostate does the rest

    Step scaling - increase or decrease the current capacity of the group based on a set of scaling adjustments, known as step adjustments, that vary based on the size of the alarm breach

    Simple scaling - incrase or decrease the current capacity of the group based on a single scaling adjustment

If you are scaling based on a utilization metric that increases or decreases proportionally to the nuimber of instaces in an Auto Scaling group, then it is recommended that you use target tracking scaling policies. Otherwise, it is better to use step scaling policies instead

1. Simple Scaling
    one rule, one action
    if cpu > 70% > add 2 instances
    after scaling > waits for cooldown period before doing anything else
    oldest and most basic policy

2. Step Scaling
    multiple rules, multiple actions based on how bad the metric is
    if cpu > 70% > add 2 instances
    if cpu > 90% > add 5 instances
    responds proportionally to severity
    no cooldown wait - acts immediately

3. Target Tracking
    you set a target metric value - AWS handles everything else
    keep CPU at 50%
    ASG automatically adds/removes instances to maintain that target
    Simplest to configure - least operational overhead
    Like a thermostat - set the temperature, it handles the rest

4. Scheduled Scaling
    scale based on time not metrics
    every monday 8 am > add 5 instances
    every sunday midnight > remove 5 instances
    used when traffic patterns are predictable

5. Predictive Scaling
    uses ML to forecast future traffic
    proactively scales before traffic hits
    combines historical patterns with real-time data


company receives semi-structured and structured data from different sources
S3 data lake
client side encryption w custom client side root key (CSE-Custom) 
big data processing framework to analyaze data and access it using various business intelligence tools and standard SQL queries

MOST high-performing solution

Use EMR to Redshift

EMR is managed cluster platfrom that simplifies running big data frameworks
like Haddop and Apache Pig

Redshift allows you to run complex analytic queries against terabytes to petabytes of structured and semi-strctured data, using sophisticated query optimization, columnar storage on high-performance storage, and massively parallel query 


company has hundreds of VPCs with multiple VPN connections to their data centers spanning 5 AWS Regions
number grows, scale its network across multiple accounts and VPCs to keep up. 
interconnect all of the company's on-premises networks, VPNs, and VPCs into a single gateway

Best solution

Set up an AWS Transit Gateway in each region to interconnect all networks within it. Then, route traffic between the transit gateways through a peering connection

Transit Gateway operates at layer 3, where the packets are sent to a specific next-hop attachment, based on their destination IP addresses

A Transit Gateway attachment is both a source and a destination of packets. You can attach the following resources to your transit gateway:
    one or more vpcs
    one or more VPN connections
    one or more AWS Direct Connect gateways
    one or more transit gateway peering connections

If you attach a transit gateway peering connection, the transit gateway must be in a different Region


 EC2 + ASG behind ALB across multiple AWS regions
 global
 majority is Japan and Sweden
 compliance requirements in these two locations, you want the japanese users to connect to the servers in the ap-northeast-1 Asia Pacific (Tokyo) region
 Swedish users should be connected to the servers in the eu-west-1 EU (Ireland) region

 fulfill the requirement

 use Route 53 Geolocation Routing Policy

Geolocation routing:
choose the resource that serve your traffic based on the geographical location of your users
meaning the DNS queries' origin

example: you want all queries from Europ to go routed to an ELB in the Frankhurt region

when you use geolocation routing, you can localize yhour content and present some or all of your website in the language of your users

you can also use geolocation routing to restrict the distribution of content to only the locations in which you have distribution rights.

Geolocation = routes by WHERE the user is. Use for compliance
Geoproximity = routes by distance between user and your resources, with a bias slider to expand/shrink a region's pull
great for shifting load/performance tuning

If the question says "must connect to" it's Geolocation
If it says "shift more traffic toward" or "bias" it's Geoproximity

If users location doesn't match any record (say a user in Brazil, and you only defined Japan + Sweden), Route 53 returns no answer/ NODATA unless you create a default location record. 


e-commerce company is in need of:
storage solution that can be simultaneously accessed by 1000 linux servers
multiple az

servers are ec2 via NFSv4 protocol. 
handle rapidly changing data at scale and high performance
highly durable
highly available when pull data, little management

most cost-effective choice to meet requirement

Amazon EFS

key: rapidlyh changing data and 1000 linux servers

file storage service = EFS

high avaiability and high scalability, POSIX-compatible file system


website accepts high-quality photos and turns photo into downloadable video montage

offers:
free and premium accounts

premium account faster processing
both go thru a single SQS and then by group of EC2 instances that generate the videos

premium users, who paid service, have higher priority than free

re-design the architecture to address the requirement

Create an SQS queue for free members and another one for premium members. Configure your EC2 instances to consume messages from the premium queue first and if it is empty, poll the free members' SQS queue

SQS for decoupling
distributed systems, scale microservices 

It's best to create two queues
one for premium members can be polled first
once completed, the messages from the free members can be processed next


whitelisted issues? bypass with CloudFront - WRONG
I'd have to whitelist configre every new IP

instead, attack at the layer 4
Network Load Balancer
handles millions, attempts TCP connection on target on the port specified in the listener configuration

based on the given scenario, web service clients can only baccess trusted I8P addresses
use BYOIP
Bring Your Own IP feature
use trusted IPs as Elastic IP addresses to a Network Load Balancer, 
you don't have to re-establish the whitelists with the new IP addresses


design an infrastructure
serverless

docker in ECR
must be deployed on a fully managed serverless compute service
Addionally, the application requires 5 GB of ephemeral storage for temporary data processing

deploy the application in an AWS Lambda function with Container image support. Set the function's storage to 5 GB

One key feature of AWS Lambda is the ability to allocate ephemeral storage for each function instace
by default, 512 MB of temporary storage
can configure up to 10 GB of storage


monitor EC2 based on a specific metric that is not readily available in CloudWatch

Memory Utilization of an EC2 instance

CloudWatch monitoring scripts are written in Perl
CloudWatch agent to get more from EC2
you can get:
    MEMORY utilization
    disk swap utilization
    disk space utilization
    page file utilization
    log collection


launch an app that trakcs GPS coordinates of trucks
coordinates are transmitted from each truck every 5 seconds
multiple consumers real-time
aggergated data will be analyzed in a separate reporting application

Kinesis

with kinesis, you can ingest realp-time data such as video, audio, application logs, webiste clickstreams, and IoT telemetry data for machine learning, analytics, and other applications. Kinesis enables you to process and analyze data as it arrives and responds instantly instaed of having to wait until all your data are collected before the processing can begin


several Reserved EC2 instances have been decommissioned
cost-effective steps in this circumstance:
    sell aws reserved instance marketplace and sell the reserved instances
    terminate the reserved instgances as soon as possible to avoid getting billed at the on-demand price when it expires


fast food company
ALB > ASG + Ec2 + Multi AZ
 handle traffic incoming from various digital devices, new routing logic to apply
 requests with URLs matching should be directed to targets

Use path conditions to define rules that forward requests to different target groups based on the URL in the request


Storage Optimized Instances:
workload that require high, sequential read and write access to very large data sets on local storage
designed to deliver tens of thousands of low-latency, random I/O operations per second (IOPS) to applications


CloudFront web distribution
static content around globe
but long login times
HTTP 504 errors. 

reduce login time and further optimize the system

cost-effective solution, select two:
    customize the content that the CloudFront web distribution delivers to your users using Lambda@Edge, which allows yopur AWS Lambda functions to execute the authentication process in AWS locations closer to the users
    Implement an origin failover by creating an origin group that includes two origins. Assign one as the primary origina and the other as secondary, which enables CloudFront to autoomatically switch if the primary orgin encounts specific HTTP status code failure responses


A global company has deployed numerous AWS Outposts servers in various remote locations worldwide. These servers frequently need to download software updates consisting of multiple files from an S3 bucket in the us-west-2 region. The company is experiencing significant delays in distributing these updates across all servers.
What solution would most effectively reduce the deployment latency while minimizing operational overhead?


Set up an Amazon CloudFront distribution with the us-west-2 S3 bucket as the primary origin and create a secondary origin in another region, implementing a CachingDisabled cache policy. Use signed URLs for downloads.
Use Amazon S3 Transfer Acceleration on the existing S3 bucket and have the Outposts servers use the Transfer Acceleration endpoint for downloads.

Create an Amazon CloudFront distribution with the us-west-2 S3 bucket as the origin. Use signed URLs for software downloads.

Set up AWS Global Accelerator to route traffic from Outposts servers to the nearest AWS edge location, then use private VIF connections to access the S3 bucket in us-west-2.

Correct
AWS Outposts is a fully managed service that brings AWS infrastructure, services, APIs, and tools directly to customer locations. It’s tailored for workloads that must remain on-premises due to low latency or the need for local data processing.

Amazon S3 is an object storage service offering industry-leading scalability, data availability, security, and performance. It’s commonly used to store large amounts of unstructured data, including datasets for machine learning.

Amazon CloudFront is a fast CDN service that securely delivers data, videos, applications, and APIs to customers worldwide, ensuring low latency and high transfer speeds. It seamlessly integrates with other AWS services and provides easy-to-use APIs for developers to customize the service to meet their needs. CloudFront utilizes a global network of edge locations to cache content closer to end users, enhancing performance and reducing the load on origin servers.

Amazon CloudFront Distribution

To address the company’s challenge of distributing large software updates to AWS Outposts servers globally with reduced latency and minimal operational overhead, use Amazon CloudFront with the S3 bucket in us-west-2 as the origin. This solution provides global content delivery through edge locations, reducing latency for all Outposts servers. It also offers caching capabilities, which can significantly speed up access to frequently downloaded files. Next, the Signed URLs add an extra layer of security for software distribution. Lastly, it can potentially reduce overall data transfer costs compared to direct S3 access, and once set up, CloudFront requires minimal ongoing management.

Hence, the correct answer is: Create an Amazon CloudFront distribution with the us-west-2 S3 bucket as the origin. Use signed URLs for software downloads.

The option that says: Set up an Amazon CloudFront distribution with the us-west-2 S3 bucket as the primary origin and create a secondary origin in another region, implementing a CachingDisabled cache policy. Use signed URLs for downloads is incorrect. While CloudFront can help distribute content globally, setting up a secondary origin in another region doesn’t add significant value. The CachingDisabled policy would only negate the benefits of CloudFront’s caching, which is crucial for reducing latency for large files.

The option that says: Set up AWS Global Accelerator to route traffic from Outposts servers to the nearest AWS edge location, then use private VIF connections to access the S3 bucket in us-west-2 is incorrect. Global Accelerator is designed to improve applications’ availability and performance, not optimize S3 downloads. It doesn’t integrate directly with S3 for file downloads. Additionally, Private VIF (Virtual Interface) is typically used with Direct Connect, not S3 buckets.

The option that says: Use Amazon S3 Transfer Acceleration on the existing S3 bucket and have the Outposts servers use the Transfer Acceleration endpoint for downloads incorrect. While this option can improve transfer speeds over long distances by leveraging Amazon’s global network infrastructure, it may not provide significant benefits for all locations, especially those closer to us-west-2. It incurs additional costs for data transfer and does not provide caching capabilities, which could benefit frequently accessed files.

 
 Look into:
 Lazy Loading to cache results?


 EKS with IAM Role
 e-commerce
 deploy and manage containers

 surge in traffic

 scale the infrastructure

 karpenter to automatically adjust the number of nodes in the EKS cluster when pods fail or are rescheduled onto other nodes
 install the kubernetes metrics server on the EKS cluster and activate the Horizontal Pod Autoscaling

 
 so far, three wrong. one is a typo error


serverless computing w/ Lambda
Lambda > MongoDB
third-party API

create an environment variables for the DB hostname, usernazme, and password, as well as the API credentials that will be used by the Lambda function for EV, SIT, UAT, and PROD environments


hybrid cloud architecture
on-premise data center to AWS

requires durable storage backup for documents stored on-premises 
a loacl cache that provides low-latency access to recnelty accessed data
documents must be stored on SMB protocol
S3 standard retrieval for 6 months and archive for anoterh decade for compliance

Mock Review:

The Bureau of Census and Statistics manages a geographic information systems (GIS) image database which has a single-table design. The system hosts high-resolution images that are uniquely identified by geographic codes. The database is updated on a minute-by-minute basis to detect any natural disasters like floods, volcanic eruptions, and other calamities.

Due to the substantial volume of data, the department wants to migrate its existing Oracle database to the AWS Cloud. The department also aims to achieve a highly available and scalable solution, particularly during critical events and high data inflow.

MOST cost-effective solution

Utilize an Amazon S3 bucket for storing the images. Launch an Amazon DynamoDB table with the geographic code as the primary key and the corresponding image S3 URL as the associated value

Utilizing Amazon S3 buckets for storing images can provide various benefits, including a centralized location for storing all images, making them easily accessible whenever needed. This can streamline the workflow and make it more efficient overall.By DynamoDB, the department can further enhance its GIS iamge database management. DynamoDB can provide fast and reliable performance, even at scale. The department can efficiently retrieve specific images based on their location by using the geographic code as the 


A company needs to accelerate the development of its GraphQL APIs for its new customer service portal. The solution must be servless to lower the monthly operating cost of the business. Their GraphQL APIs must be accessible via HTTPS and have a custom domain.

What solution should the Solutions ARchitect implement to meet the above requirements?

Develop the application using the AWS AppSync service and use its built-in custom domain feature. Associate an SSL certificate to the AWS AppSync API using the AWS Certificate Manager (ACM) service to enable HTTPS communication.

AWS AppSync is a serverless GraphQL and Pub/Sub API service that simplifies building modern web and mobile applications. It provides a robuts, scalable GraphQL interface for application developers to combine data from multiple sources, including Amazon DynamoDB, AWS Lambda, and HTTP APIs.

The difference of:
Geoproximitiy
Geolocation

Geolocation: routes based on WHERE THE USER IS
Geoproximity: routes based on DISTANCE between the user and your SERVERS

Generate a Lambda Function URL
Deploy HTTPS endpoint on the Lambda function

and

use it as the webhook for the third-party analytics service
use the sercured network endpoint for the third-party apps

STS:
STS gives out temporary credentials
short lived = safer

STS credentials:
    1. Access key ID
    2. Secret access key
    3. Session token < this third piece is the tell. Permanent credentials have only the first two. "Session Token" means temporary


### Category: CSAA - Design Secure Architectures

A large financial firm needds to set up a Linux bastion host to allow access to the Amazon EC2 instances running in their VPC. For security purposes, only the clients connecting from the corporate external public IP address 175.45.116.100 should have SSH access to the host.

SG inbound rule: Protocol -TCP. Port Range -22, Source 175.45.116.100/32

A bastion host sits in a public subnet so people can reach it from the internet - but "public subnet" doesn't decide how you control access to it. 

Every EC2 instance is protected by two layers at once: NACL at the subnet's edge and SG around instance level.

If you allow one specific IP to SSH into one specific host - that's SG


An application is hosted in an Auto Scaling group of EC2 instances and a Microsoft SQL Server on Amazon RDS. There is a requirement that all in-flight data between applications and RDS should be secured.

Which of the following options is the MOST suitable solution that you should implement?

Download the Amazon RDS Root CA certificate. Import the certificate to your servers and configure your application to use SSL to encrypt the connection to RDS.

Force all connections to your DB instance to use SSL by setting the rds.force_ssl parameter to true. Once done, reboot your DB instance.

In order for you to establish an SSH connection from your home computer to your EC2 instance, you need to do the following:
    On the security group, add an inbound rule to allow ssh traffic to EC2
    On the NACL, add both inbound and outbound rule to allow ssh traffic to your ec2


A company developed a meal planning application that provides meal recommendations for the week, as well as the food consumption of the users. The application resides on an EC2 instance, which requires acesss to variouis AWS service for its day-to-day operations.

Which of the following is the best way to allow the EC2 instances to access the Amazon S3 bucket and other AWS services?

Create a role in IAM and assign it to the EC2 instance

Create a role in IAM and assign it to the EC2 instance.

best practice in handling API Credentials is to create a new role in IAM service and then assign it to the specific EC2 instace. 


A company has a web application that uses Amazon CloudFront to distribute its images, videos, and other static content stored in its Amazon S3 bucket to users around the world. The company has recently introduced a new member-only access feature for some of its high-quality media files. There is a requirement to provdie access to multiple private media files only to paying subscribers without having to changvbe the current URLs.

Which of the following is the most suitable solution to implement to satisfy this requirement?

Use Signed Cookies to contorl who can access the private files in your CloudFront distribution by modifying your application to determine whether a user should have access to your content. For members, send the requ ired Set-Cookie headers to the viewer which will unlock the content only to them.

CloudFront signed URLs and signed cookies provide the same basic functionality: they allow you to control who can access your content

Signed URLs:
    you want to use an RTMP distribution. Signed cookies aren't supported for RTMP distributions
    you want to restrict access to indifvidual files, for example, an installation download for your applicatiuon
    your users are using a client (for example, a custom HTTP client) that doesn't support cookies.
Signed cookies:
    you want to provide access to multiple restricted files, for example, all of the files for a video in HLS format or all of the files in the subscribers area of a website
    you don't want to change the current URLs


A top IT Consultancy has a VPC with two On-Demand EC2 instances with Elastic IP addresses. You were notified that the EC2 instances are currently under SSH brute force attacks over the Internet. The IT Security team has identified the IP addresses where these attacks orginated. you have the immediately implement a temporary fix to stop these attacks while the team is setting up AWS WAF, GuardDuty, and AWS Shield Advanced to permanently fix the security vulnerability.

Which of the following provides the quickest way to stop the attacks to the instances?

Block the IP addresses in the Network Access Control List

A network ACL contains a numbered list of rules that we evaluate in order, starting with the lowest numbered rule, to determine whether traffic is allowed in or out of any subnet associated with the network ACL. The highest number that yolu can use for a rul,e is 32766. We recommend that you start by creating rules of increments so that you can insert new rules where you need to later on.


A solutions architect is writing an AWS Lambda function that will process encrypted documents from an Amazon FSx for NetApp ONTAP file system. The doucments are protected by an AWS KMS customer key. After processing the documents, the Lambda function will store the results in an S3 bucket with an Amazon S3 Glacier Flexible Retrieval storage class. The solutions architect must ensure that the files can be decrypted by the Lambda function.

What action accomplishes the requirement?

Attach the kms:decrypt permission to the Lambda function's execution role. Add a sttement to the AWS KMS key's policy that grants the functionk's exectuion role the kms:decrypt permission.

Lambda interacts with other AWS services using the permissions associated with an execution role


A company has clients all across the globe that access product files stored in several Amazon S3 buckets, which are behind each of trhe respective Amazon CloudFront web distributions. The company currently wants to deliver conten to a specific client, ensuring that only that client can access the data. At present, all clients can access the S3 buckets directly using an S3 URL or through the ClouidFront distribution. The Solutions Architect must serve the private content via CloudFront only, to secure the distribution of files.

Which combination of actions should the Architect implement to meet the above requirements?

Require the users to access the private content by using special CloudFront signed URLs or signed cookies

Restrict access to files in the origin by creating an origin access control (OAC) and giving it permission to read the files in the bucket


A company is designing a banking portal that uses Amazon ElastiCache for Rdis as its distributed session management component. To secure seession data and ensure that Cloud Engineers must authenticate before executing Redis commands, specifically MULTI EXEC commands, the system should enforce strong authentication by requirering users to enter a password. Additionally, access should be managed with long-lived credentials while supporting robust security practices.

Which of the following actions should be taken to meet the above requirement?

Authenticate the users using Redis AUTH by creating a new Redis Cluster with both the --transit-encryption-enabled and --auth-token parameters enabled.

Using Redis AUTH command can improve security by requiring the user to enter a password before they are granted permission to execute Redis commands on a password-protected Redis server.

To require that users enter a password on a password-protected Redis server, include the parameter --auth-token with the correct password when you create your replication group of cluster and on all subsequent commands to the replication group of cluster.

Well Architect Framework:

Performance Efficiency
Cost Optimization
Sustainability
Operational Excellence
Security
Reliability


Sample Microservice Design?
Solution's Architect BnB

Microservice with ALB

Domain in Route 53 and hosted zone, record A for that custom domain will point to the ALB

path based routing and target group

www.store.com/browse > send traffic to a target group: EC2 + ASG + DB
www.store.com/purchase > send to EC2
www.store.com/return > different gbackend

different text stack
polyglot


4 types of DR:
1. Backup - 12 hours to get up
2. Pilot Light - img of servers, backup to cloud, 
3. Warmup Standby - ASG - 45 minutes to an hour
4. Active - Active - 


A startup launched a new FTP server using an On-Demand EC2 instance in a newly created VPC with default settings. The server should not be accessbile publicly but only through the IP address 175.45.116.100 and nowhere else.

Which of the following is the most suitable way to implement this requirement?

Create a new inbound rule in the security group of the EC2 instance with the following details:
Protocol: TCP
Port Range: 20-21
Source: 175.45.116.100/32


For data privacy, a healthcare company has been asked to comnply with the Health Insurance Portability and Accountability Act (HIPAA). The company stores all its backups on an Amazon S3 bucket. It is required that data stored on the S3 bucket must be encrypted.

What is the best option to do this? 

Before sending the data to S3 over HTTPS, encrypt the data locally first using your own encryption keys.

Enable Server-Side Encryption on an S3 bucket to make use of AES-256 encryption.


An application is hosted on an EC2 instance with multiple EBS volumes attached and uses Amazon Neptune as its database. To improve data security, you encrypted Amazoln Elastic Block Store volumes?

Snapshots are automatically encrypted
All data moving between the volume and the isntace are encrypted

EBS provides block-level storage volumes for use with EC2 instances. EBS volumes are highly available and reliable storage volumes that can be attached to any running instance that is in the same AZ. EBS volumes that are attached to an EC2 instace are exposed as storage volumes that presist independently from the life of the instance

When you create an encrypted EBS volume and attach it to a supported instance type, the following types of data are encrypted:
    data at rest inside the volume
    all data moving between the volume and the instance


An organization needs to control access to severate Amazon S3 buckets. The organization plans to use a gateway endpoint to allow access to trusted buckets. The organization shall not use overly broad policies like AmazonS3FullAccess.

Which of the following could help achieve this requirement?

Generate an endpoint policy for trusted S3 buckets

A Gateway endpoint is a type of VPC endpoint that provides reliable connectivity to Amazon S3 and DynamoDB without requirirng an internet gateway or a NAT device for your VPC. Instances in you r VPC do not require public IP addresses to communicate with resources in the service.

When you create a Gateway endpoint, you can attach an endpoint policy that contorls accress to the service to which you are connecting. You can modify the endpoint policy attached to your endpoint and add or remove the route tables used byt he endpoint. An endpoint policy does not overrride or replace IAM user p9olicies or service-specified policies


 A Solutions Architect created a brand new IAM user with a default setting using AWS CLI. This is intended to be used to send API requests to Amazon S3, DynamoDB, Lambda, and other AWS resources of the company's infrastructure.

 Which of the following must be done to allow the user to make API calls to the AWS resources?

 Create a set of Access Keys for the user and attach the necessary permissions.

 You need two things every API call needs:
 1. Access keys
 2. IAM policy


A company has a requirement to move an 80 TB data warehouse to the cloud. It would take 2 months to transfer the data based on the current bandwidth allocation. 

Which option is the most cost-effective for quick data upload to AWS?

AWS Data Transfer Terminal

Replacing Snow Family

A company has established a dedicated network connection from its on-premises data center to AWS Cloud using AWS Direct Connect (DX). The core network services, such as the Domain name System (DNS) service and Active Directory services, are all hosted on-premises. The company has new AWS accounts that will also require consistent and dedicated access to these network services.

Which of the following can satisfy this requirement with the LEAST AMOUNT OF OPERATIONAL OVERHEAD and in a cost-effective manner?

Create a new Direct Connect gateway and intergrate it with the existing Direct Connect connection. Set up a Transit Gateway between AWS accounts and associate it with the Direct Connect gateway.

VPN connection traverses the public internet and doesnt use a dedicated connection


A company has stored 200 TB of backup files in Amazon S3. The files are in a vender-proprietary format. The Solutions Architect needs to use the vender's proprietary file conversion to retrieve files from an S3 bucket, convert the files to an industry-standar5d format, and re-upload the converted files to S3. The solution must minimize the data transfer costs.

Which of the following options can satisfy the given requiremtn?

Deploy the Amazon EC2 instance in the same Region as S3. Install the file conversion software on the instance. Perform data transformation and re-upload it to S3.

A car dealership website hosted in EC2 stores car listings in an Amazon Aurora database managed by Amazon RDS. Once a vehicle has been sold, its data must be removed from the current listings and forwarded to a distributed processing system.

Which of the following options can satisfy the given requirement?

Use an Aurora MySQL native function to invoke an AWS Lambda function whenever a vehicle listing is deleted. Configure  the lambda function to send the data to an SQS for the distributed processing system to consume.


A company has a web application hosted in their on-premises infrastructure that they want to migrate to AWS cloud. 
Your manager has instructed you to ensrue that there is no downtime while the migration process is on-going. In order to achieve this, your team decided to divert 50% of the traffic to the new application in AWS and the other 50% to the application hosted in their on-premises infrastructure. Once the migration is over and the application works with no issues, a full diversion to AWS will be implemented. The company's VPC is connected to this on-premises network via an AWS Direct Connect connection.

Use a Application Elastic Load balancer with Weighted Target Groups to divert and proportion the traffic the on-premises and AWS-hosted application. Divert 50% of the traffic to the new application in AWS and the other 50% to the application hosted in their on-premises infrastructure

Route 53 with Weighted routing policy to divert the tr4affic between the on-premises and AWS-hosted application. Divert 50% of the traffic to the new application in AWS and the other 50% to the aplication hosted in their on-premises infrstructure.


What is AWS SAM?

A travel company has a suite of web applications hosted in an Auto Scaling group of On-Demand EC2 instances bheind an Application Load Balancer that handles traffic from various web domains such as i-love-manila.com, i-love-boracay.com, i-love-cebu.com and many others. To improve secruity and lessen the overall cost, you are instructed to secure the system by allowing mulitple domains to serve SSL traffic without the need to reauthenticate and reprovision your certificate everything you add a new domain. This migration from HTTP to HTTPS will help imrpove their SEO and Google search ranking.

Which of the following is the most cost-effective solution to meet the above requirement?

Upload all SSL certificates of the domains in the ALB using the console and bind multiple certificates to the same secure listener on your load balancer. ALB will automatically choose the optimal TLS certificate for each client using Server Name Indication (SNI)


An organization leverages Amazon VPC to host its multi-tier services. The organization aims to provide a web analytics service via RESTful APIs to a user base spanning millions. Access to these APIs requires user verification through an aut6hentication service. The APIs will be exposed through secure HTTP endpoints.


CloudHSM question?
Lost key, how can you get it back?

Amazon Macie
Amazon Kendra

Prometheus
Grafana

Management Events

A company is planning to deploy a High Performance Computing (HPC) cluster in its VPC that requires a scalable, high-performance file system. The storage service must be optimized for efficient workload processing, and the data must be accessible via a fast and scalable file system interface. It should also work natively with Amazon S3 that enables you to easily process your S3 data with a high-performance POSIX interface.

Which of the following is the MOST suitable service that you should use for this scenario?

Amazon Elastic File System (EFS)
Amazon FSx for Windows File Server
Amazon FSx for Lustre
Amazon Elastic Block Storage (EBS)


A company is using a combination of Amazon API Gateway and AWS Lambda for the web services of an online web portal that is accessed by hundreds of thousands of clients each day. The company will be announcing a new revolutionary product, and it is expected that the web portal will receive a massive number of visitors from all around the globe. 

How can the back-end systems and applications, beyond the subnet-level filtering of network ACLs, be protected from traffic spikes?

Use throttling limits in API Gateway

For microservices, I can set throttoling limits in API Gateway to help against traffic spikes

List to look over:
Pagination
Cache Stampede
idempotency
graphql
gRPC
OAuth
Composite Index
CAP Theorem
Circuit Breaker
Livelock
CSRF
False Sharing
mTLS


A real-time data analytics application is using AWS Lambda to process data and store results in JSON format to an S3 bucket. To speed up the existing workflow, you have to use a service where you can run sophisticated Big Data anaylytics on your data without moving them into a separrate anaylyticcs system.

Which of the following grouip of services can you use to meet this requirement?

Amazon Athena, Amazon Redshift Spectrum, AWS Glue

Amazon Athena, Amazopn Redhshift Spectrum, and AWS Glue are highly relevat services for performing Big Data  analytics directly on data stored in Amazon S3, without needing to move the data to a separate system.

Amazon Athena: allows usedrs to query data directly in S3 using SQL, providing a serverless approach to perform analytics on S3-stored data in formats such as JSON

Amazon Redshift Spectrum extends the querying capabilities of Amazon Redshift to also access and analyze structured and semi-structured data in S3, supporting large-scale analytics.

AWS Glue is a fully managed ETL (Extract, Transform, Load) service that helps catalog, prepare, and transform data in S3 for analytics, simplifying Big Data workflows.


AWS License Manager is a service that makes it easier for you to manage your software licenses from software vendors (for example, Microsoft, SAP, Oracle, and IBM) centrally across AWS and your on-premises environments. This provides control and visibility into the usage of yoru licenses, enabling you to limit licensing overages and reduce the risk of non-complaince and misreporting. 

A company is running a dashboard application on a Spot EC2 instance inside a private subnet. The dashboard is reachable via a domain name that maps to the private IPv4 address of the instance’s network interface. A solutions architect needs to increase network availability by allowing the traffic flow to resume in another instance if the primary instance is terminated.

Which solution accomplishes these requirements?

Create a secondary elastic network interface and point its private IPv4 address to the application’s domain name. Attach the new network interface to the primary instance. If the instance goes down, move the secondary network interface to another instance.

Set up AWS Transfer for FTPS service in Implicit FTPS mode to automatically disable the source/destination checks on the instance’s primary elastic network interface and reassociate it to another instance.
Use the AWS Network Firewall to detach the instance’s primary elastic network interface and move it to a new instance upon failure.
Attach an elastic IP address to the instance’s primary network interface and point its IP address to the application’s domain name. Automatically move the EIP to a secondary instance if the primary instance becomes unavailable using the AWS Transit Gateway.


on-premise MySQL database needs replication in S3 as CSV files
eventually launched on aurora serverless cluster + rds proxy

once db copied, ongoing changes to the on-premises database should be continually streamed to S3
implement little management overhead and secure
what ingestion pattern should take?

Create a full load and change data capture (CDC) replication task using AWS Database Migration Service (AWS DMS)
Ad a new Certificate Authority (CA) certificate and create a DMS endpoint with SSL


A company has recently migrated its microservices-based application to EKS. As part of the migration, the company must ensure that all senstive configuration data and credentials, such as database passwords and API keys, are stored securely and encrypted within the EKS cluster's etcd key-value store.

Enable secret encryption with a new AWS KMS key on an existing Amazon EKS cluster to encrypt sensitive data stored in the EKS cluster's etcd key-value store


A FinTech startup deployed an application on an Amazon EC2 instance with attached Instance Store volumes and an Elastic IP address.


A company wants to organize the way it tracks its spending on AWS resources. A report that summarizes the total billing accrued by each department must be generated at the end of the month. The company already uses a Savings Plan for pricing, but that does not break down costs by department.

Which solution will meet the requirements?

Tag resources with the department name and enable cost allocation tags

A tag is a label that you or AWS assigns to an AWS resource. Each tag cosists of a key and a value. For each resource, each tag key must be unique, and each tag key can have only one value. You can use tags to organize your resources and cost allocation tags to track your AWS costs on a detailed level.

After tags are applied to EC2 and S3, you activate the tags in the Billing and Cost Management console,
AWS generates a cost allocation report as a comma-separated value (CSV file)


A comapny has established a dedicated netwrok connection from its on-premises data center to AWS cloud using AWS DX. 

Create a new Direct Connect gateway and integrate it with the existing Direct Connect connection. Set up a Transit Gateway between AWS accounts it with the Direct Connect gateway


AWS Config provides a detailed view of the configuration of AWS resources in your AWS account. This includes how the resources are related to one another and how they were configured in the past so that you can see how the configurations and relationships change over time

Use the AWS Config managed rule to check if the IAM user access keys are not rotated within 90 days. Create an Amazon EventBridge rule for the non-compliant keys, and define a target to invoke a custom AWS Lambda function to deactivate and delete the keys


A company has a web application that uses Amazon CloudFront to distribute its images, videos, and other static content stored in its Amazon S3 bucket to users around the world. The company has recently introduced a new member-only access feature for some of its high-quality media files. There is a requirement to provide access to multiple private media files only to paying subscribers without having to change the current URLs.

Which of the following is the most suitable solution to implement to satisfy this requirement?

Use Signed Cookies to control who can access the private files in your CloudFront distribution by modifying your application to determine whether a user should have access to your content. For members, send the required Set-Cookie headers to the viewer which will unlock the content only to them.

Many companies that distribute content over the internet want to restrict access to documents, business data, media streams, or content that is intended for selected users, for example, users who have paid a fee. To securely serve this private content by using CloudFront, you can do the following:

1. Require that your users access your private content by using special CloudFront signed URLs or signed cookies.
2. Require that your users access your content by using CloudFront URLs, not URLs that access content directly on the origin server (for example, Amazon S3 or a private HTTP server). Requiring CloudFront URLs isn't necessary, but we recommend it to prevent users from bypassing the restrictions that you specify in signed URLs or signed cookies

signed URLs when:
    1. you want to use an RTMP distribution. SIGNED COOKIES aren't supported for RTMP distributions
    2. restrict access to individual files
    3. your users are using a client that doesn't support cookies

signed cookies when:
    1. multiple restrictef files. files for a video in HLS format or all files in the subscribers area of a website
    2. you don't want to change your current URLs


A company is using Amazon S3 to store frequently accessed data. When an object is created or deleted, the S3 bucket will send an event notification to the Amazon SQS queue. A solutions architect needs to create a solution that will notify the development and operations team about the created or deleted objects.

Which of the following would satisfy this requirement?

Create an Amazon SNS topic and configure two SQS queues to subscribe to the topic. Grant S3 permission to send notifications to SNS and update the bucket to use the new SNS topic.

You cannot attach two or more SNS topics or SQS queues for S3 event notifications


A company is experiencing repeated outages in the availability Zone where its Amazon RDS database instance is deployed, resulting in a complete loss of access to the database during each incident. The team evaluated a multi-site active/active deployment but found that it requires cross-Region synchronization, whereas a simpler embedded solution would suffice.

Enable Multi-AZ failover

For Amazon Aurora, the failover involves promoting a replica to become the new writer instance.


A global IT company with offices around the world has multiple AWS accounts. To improve efficiency and drive costs down, the CIO (Chief Information Officer) wants to set up a solkution that centrally manages their AWS resources. This will allow them to proure AWS resources centrally and share resources such as AWS tRansit Gzteways, AWS License manager configurations, or Amazon Route 53 Resolver rules across their various accounts

Consolidate all of the company's accounts using AWS Organizations

Use the AWS Resource Access Manager (RAM) service to easily and securely share your resources with your AWS accounts.


A popular augmented reality (AR) mobile game is heavily using a RESTful API which is hosted in AWS. The API uses Amazon API Gateway and a DynamoDB table with a preconfigured read and write cpacity. Based on your systems monitoring, the DynamoDB tab le begins to throttle requests. during high peak loads which causes the slow performance of the game.

Which of the following can you do to improve the performance of your app?

Use DynamoDB Auto Scaling

DynamoDB table doesnt Auto Scale like that


A Solutions Architect is working for a large global media company with multiple office locations all around the world. The Architect is instructed to build a system to distribute training videos to all employees.

Using Amazon CloudFront, what method would be used to serve content that is stored in Amazon S3 but not publicly accessible from S3 directly?

Create an Orgin Access Control (OAC) for CloudFront and grant access to the objects in the S3 bucket to the OAC


A media company recently launched their newly created web application. Many users tried to visit the website, but they are receiving a 503 Service Unavailable Error. The system administrator tracked the EC2 instance status and saw a capacity is reaching its maximum limit and unable to process all the requests. To gain insights from the application's data, they need to launch a real-time analytics service.

Which of the following allows you to read records in batches?

Create a Kinesis Data Stream and use AWS Lambda to read records from the data stream


A Solutions Architect is managing a three-tier web application that processes credit card payments and online transactiopns. Static web pages are used on the front-end tier while the application tier contains a single EC2 instgance that handles long-running processes. The datga is stored in a MySQAL database. The Solutions Architect is instructed to decouple the tiers to create a highly available application


AWS Network Firewall is a stateful, managed, network firewall, and intrusion detection and prevention service for your VPC. Network Firewall uses Suricata - open source intrusion prevention system for stateful inspection

Network Access Analyzer
feature of VPC that reports on unintended access to your AWS resources based on the security and compliance that you set. This service is not capable of performing deep packet inspection on traffic entering or leaving your VPC, unlike AWS Network Firewall


Please Don’t overcomplicate it. 

• Build a Password Manager to learn file handling, hashing (not full crypto)
• Build a URL Shortener to understand routing, IDs, and persistence
• Build a Todo App with deadlines to practice CRUD and basic state
• Build a Web Scraper to learn requests, parsing, and rate limits
• Build a CLI Expense Tracker to master logic, files, and edge cases
• Build a Log Analyzer to work with files, timestamps, and patterns
• Build a Simple Recommender using similarity rules (not ML magic)
• Build an Email Automation Script using SMTP and scheduling

PROJECTS. Not tutorials.

A company is looking for a way to analyze the calls between customers and service agents. Each conversation is transcribed, JSON-formatted, and saved to an Amazon S3 bucket. The company’s solutions architect is tasked to design a solution for extracting and visualizing sentiments from the transcribed files.

Which solution meets the requirements while minimizing the amount of operational overhead?

Analyze the JSON files with Amazon Textract. Index the sentiment along with the transcript to an Amazon OpenSearch cluster. Visualize the results using Amazon Managed Grafana.
Create an Amazon Comprehend analysis job. Index the sentiment along with the transcript to an Amazon OpenSearch cluster. Visualize the results using the OpenSearch Dashboard.
Train a custom Natural Language Processing (NLP) model using Amazon SageMaker. Index the sentiment along with the transcript to an Amazon OpenSearch cluster. Visualize the results using the OpenSearch Dashboard.
Create an Amazon Comprehend analysis job. Index the sentiment along with the transcript to an Amazon OpenSearch cluster. Visualize the results using Amazon Managed Grafana.


A company has multiple AWS Site-to-Site VPN connections placed between their VPCs and their remote network. During peak hours, many employees are experiencing slow connectivitiy issues, which limits their productivity. The company has asked a solutions architect to scale the throughput of the VPN connections.

Which solution should the architect carry out?

Associate the VPCs to an Equal Cost Multipath Rou8ting (ECMR)-enabled transit gateway and attach additional VPN tunnels


A company has a multiple AWS Site-to-Site VPN connections placed between their VPCs and their remote network. During peak hours, many employees are experiencing slow connectivity issues, which limits their productivitiy. The company has asked a solutions architect to scale the throughput of the VPN connections.

Which solution should the architect carry out?

How to scale the throuput of a VPN connection

Associate the VPCs to an Equal Cost Multipath Routing (ECMR)-enabled transit gateway and attach additional VPN tunnels


A game company has a requirement of load balancing the incoming TCP traffic at the transport level (Layer 4) to their containerized gaming servers hosted in AWS Fargate. To maintain performance, it should handle millions of requests per second sent by gamers around the globe while maintaining ultra-low latencies.

Which of the following must be implemented in the current architecture to satisfy the new requirement?

Launch a new Network Load Balancer

ALB is Layer 7
NLB is Layer 4


A company that is rapidly growing in recent months has been in the process of setting up IAM users on its single AWS Account. A solutions architect has been tasked to handle the user management, which includes jgranting read-only access to users and denying permissions whenever an IAM user has no MFA setup. New users will be added frequently based on their respective departments.

Which of the following actions is the MOST secrure way to grant permissions to the new users?

Launch an IAM Group for each department. Create an IAM Policy that enforces MFA authentication with the least privilege permission. Attach the IAM Policy to each IAM Group.


A company runs its multitier online shopping platform on AWS. 
Every new sale transaction is published as a message in an open-source RabbitMQ queue that runs on an Amazon EC2 instance. 
There is a consumer application is hosted on a separate EC2 instance that consumes the incoming messages, which then stores the transaction in a self-hosted PostgreSQL database on another EC2 instance.

All of the EC2 instances used are in the same Availability Zone in the eu-central-1 Region. 
A solutions architect needs to redesign its cloud architecture to provide the highest availability with the least amount of operational overhead.

What should a solutions architect do to meet the company’s requirements above?


An online cryptocurrency exchange platform is hosted in AWS, utilizing an Amazon ECS Cluster and Amazon RDS in a Multi-AZ Deployments configuration. 
The application heavily uses the RDS instance to process complex read and write database operations. 
To maintain reliability, availability, and performance, it is necessary to closely monitor how the different processes or threads on a DB instance use the CPU, including the percentage of CPU bandwidth and total memory consumed by each process.

Which of the following is the most suitable solution to monitor the database properly?

Enable Enhanced Monitoring in RDS

Amazon RDS offers a powerful feature known as Enhanced Monitoring, which provides detailed metrics in real-time about the operating system (OS) underlying your database instances. This feature allows users to monitor performance at a granular level through the AWS Management Console or by accessing the Enhanced Monitoring JSON output via CloudWatch Logs. By default, these metrics are retained in CloudWatch Logs for 30 days, but this retention period can be adjusted by modifying the retention settings for the RDSOSMetrics log group in CloudWatch.


A global IT company with offices around the world has multiple AWS accounts. To improve efficiency and drive costs down, the Chief Information Officer (CIO) wants to set up a solution that centrally manages their AWS resourcese. This will allow them to procure AWS resources centrally and share resources such as AWS Transit Gateways, AWS License Manager configurations, or Amazon Route 53 Resolver rules across their various accounts.

As the Solutions Architect, which combination of options should you implement in this scenario?

Consolidate AWS Organizations
Use the AWS Resource Access Manager (RAM) service to easily and securely share your resources with your AWS accounts.


WAF operates at Layer 7
the application layer - it reads HTTP requests, sees the actual SQL in the payload

Study SAA, Drink water, Gym, Python 1 Hour, SAA 4 hour block, Project CRUD 1 Hour


A docker application, which is running on an ECS cluster behind a lod balancer
heavy dynamoDB
distribute workload evenly and provisioned throughput efficiently
Currently, the table's write capacity units are unevenly consumed due to key distribution


which of the following should be implemented for the dynamodb table?

use partition keys with high-cardinality attributes, which have a large number of distinct values for each item.

Partition key - also called a rang key
Sort Key - range key


I need to examing this question:
A software development company is using serverless computing with AWS Lambda to build and run applications without having to set up or manage servers. The company has a Lambda function that connects to a MongoDB Atlas, which is a popular Database as a Service (DBaaS) platform, and also uses a third-party API to fetch certain data for its application. One of the developers was instructed to create the environment variables for the MongoDB database hostname, username, and password, as well as the API credentials that will be used by the Lambda function for DEV, SIT, UAT, and PROD environments.

Considering that the Lambda function is storing sensitive database and API credentials, how can this information be secured to prevent other developers on the team, or anyone, from seeing these credentials in plain text? Select the best option that provides maximum security.

There is no need to do anything because, by default, Lambda already encrypts the environment variables using the AWS Key Management Service.
Create a new AWS KMS key and use it to enable encryption helpers that leverage on AWS Key Management Service to store and encrypt the sensitive information.
Enable SSL encryption that leverages on AWS CloudHSM to store and encrypt the sensitive information.
Lambda does not provide encryption for the environment variables. Deploy your code to an Amazon EC2 instance instead.
Correct
When you create or update Lambda functions that use environment variables, AWS Lambda encrypts them using the AWS Key Management Service. When your Lambda function is invoked, those values are decrypted and made available to the Lambda code.

The first time you create or update Lambda functions that use environment variables in a region, a default service key is created for you automatically within AWS KMS. This key is used to encrypt environment variables. However, if you wish to use encryption helpers and use KMS to encrypt environment variables after your Lambda function is created, you must create your own AWS KMS key and choose it instead of the default key. The default key will give errors when chosen. Creating your own key gives you more flexibility, including the ability to create, rotate, disable, and define access controls, and to audit the encryption keys used to protect your data.

Create a new KMS key and use it to enable encryption helpers that leverage on AWS Key Management Service to store and encrypt the sensitive information.

Hence, the correct answer is: Create a new AWS KMS key and use it to enable encryption helpers that leverage on AWS Key Management Service to store and encrypt the sensitive information.

The option that says: There is no need to do anything because, by default, Lambda already encrypts the environment variables using the AWS Key Management Service is incorrect. Although Lambda encrypts the environment variables in your function by default, the sensitive information would still be visible to other users who have access to the Lambda console. This is because Lambda uses a default KMS key to encrypt the variables, which is usually accessible by other users. The best option in this scenario is to use encryption helpers to secure your environment variables.

The option that says: Enable SSL encryption that leverages on AWS CloudHSM to store and encrypt the sensitive information is also incorrect since enabling SSL would encrypt data only when in-transit. Your other teams would still be able to view the plaintext at-rest. Typically, AWS KMS is the recommended choice for encrypting sensitive data at rest.

The option that says: Lambda does not provide encryption for the environment variables. Deploy your code to an Amazon EC2 instance instead is incorrect since, as mentioned, Lambda does provide encryption functionality of environment variables.


