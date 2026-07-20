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

### 1. Scenario: You have a microservices application that needs to scale dynamically based on traffic. How would you design an architecture for this using AWS services?

I would design my microservices as containers, so ECS on Fargate for orchestration and AWS manages the machine. Each one is a service that keeps a desired number of tasks running and relaunches crashes. An ALB routes requests to each service via URL path. Auto Scaling raises or lowers tasks based on the number of request per task.

### 2. Scenario: Your application's database is experiencing performance issues. Describe how you would use AWS tools to troubleshoot and resolve this.

before:I would use Amazon RDS Performance Insights to identify bottlenecks, CloudWatch Metrics for monitoring, and AWS X-RAY for tracing requests. I'd also consider optimizing queries and using read replicas if necessary.

after:
common RDS:
read-heavy load = read replica
repeated identical reads - elasticache 
write bottleneck - scale up/shard

common DynamoDB:
read-heavy load = on-demand capacity scales reads
repeated identical reads = DAX
write bottleneck = raise write capacity

Regardless of DB, I'd start with CloudWatch metrics to understand what kind of pressure the database is under - CPU, memory, read/write latency
That tells me if it's compute-bound, connection-exhausted, or disk-bound

### 3. Scenario: You're migrating a monolithic application to a microservices architecture. How would you ensure smooth deployment and minimize downtime?

I would adopt a "strangler" pattern, gradually migrating components to microservices. This minimizes risk by replacing pieces of the monolith over time, allowing for testing and validation at each step.

### 4. Scenario: Your team is frequently encountering configuration drift issues in your infrastructure. How could you prevent and manage this effectively?

I would implement Infrastructure as Code (IaC) using AWS CloudFormation or Terraform. By versioning and automating infrastructure changes, we can ensure consistent and repeatable deployments.

### 5. Scenario: Your company is launching a new product, and you expect a sudden spike in traffic. How would you ensure the application remains responsive and available?

I would implement a combination of auto-scaling groups, Amazon CloudFront for content delivery, Amazon RDS read replicas, and Amazon DynamoDB provisioned capacity to handle increase load while maintaining performance.

### 6. Scenario: You're working on a CI/CD pipeline for a containerized application. How could you ensure that every code change is automatically tested and deployed?

I would set up an AWS CodePipeline that integtrates with AWS CodeBuild for building and testing containers. After succesfful testing, I'd use AWS CodeDeploy to deploy the containers to an ECS cluster or Kubernete on EKS.

### 7. Scenario: Your team wants to ensure secure access to AWS resources for different team members. How could you implement this?

I would use AWS Identity and Access Management (IAM) to create fine-grained policies for each team member. IAM roles and groups can be assigned permissions based on least priviledge principles.

### 8. Scenario: You're managing a complex microservices architecture with multiple services communicating. How could you monitor and trace requests across services?

I would integrate AWS X-Ray into the application to trace requests as they traverse services. This would provide insights into latency, errosr, and dependencies between services.

### 9. Scenario: Your application has a front-end hosted on S3, and you need to enable HTTPS for security. How would you achieve this?

I would use Amazon CloudFront to distrtibute content from the S3 bucket, configure a custom domain, and associated an SSL/TLS certificate through AWS Certificate Manager.

### 10. Scenario: Your organization has multiple AWS accounts for different environments (dev, staging, prod). How would you manage centralized billing and ensure cost optimization?

I would use AWS Organizations to manage multiple accounts and enable consolidated billing. AWS Cost Explorer and AWS Budgets could be used to monitor and optimize costs across accounts.  

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