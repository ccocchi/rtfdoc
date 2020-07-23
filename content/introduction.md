---
id: introduction
menu_title: Introduction
---

# Introduction

<p class="intro">
The Stripe API is organized around REST. Our API has predictable resource-oriented URLs, accepts form-encoded request bodies, returns JSON-encoded responses, and uses standard HTTP response codes, authentication, and verbs.
</p>

You can use the Stripe API in test mode, which does not affect your live data or interact with the banking networks. The API key you use to authenticate the request determines whether the request is live mode or test mode.

```attributes
name:
  type: string
  desc: the actual object you're getting
  required: true
address:
  type: hash
  desc: details about user's address
  children:
    - city:
        type: string
        desc: english name of the city
```

$$$

```response
{
  "id": "mandate_1H0E6T2eZvKYlo2Cy4ALkgmZ",
  "object": "mandate",
  "customer_acceptance": {
    "accepted_at": 123456789,
    "online": {
      "ip_address": "127.0.0.0",
      "user_agent": "device"
    },
    "type": "online"
  },
  "livemode": false,
  "multi_use": {},
  "payment_method": "pm_123456789",
  "payment_method_details": {
    "sepa_debit": {
      "reference": "123456789",
      "url": ""
    },
    "type": "sepa_debit"
  },
  "status": "active",
  "type": "multi_use"
}
```
