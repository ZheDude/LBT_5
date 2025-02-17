# This file contains every command for every DNS entry needed.


Add-DnsServerResourceRecordPtr -Name "10" `
    -ZoneName "0.168.192.in-addr.arpa" `
    -PtrDomainName "DC1.corp.murbal.at" `
    -ComputerName DC1.corp.5cn.at

Add-DnsServerResourceRecordPtr -Name "11" `
    -ZoneName "0.168.192.in-addr.arpa" `
    -PtrDomainName "DC2.corp.murbal.at" `
    -ComputerName DC1.corp.5cn.at

Add-DnsServerResourceRecordPtr -Name "12" `
    -ZoneName "0.168.192.in-addr.arpa" `
    -PtrDomainName "I-CA.corp.murbal.at" `
    -ComputerName DC1.corp.5cn.at