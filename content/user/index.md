---
path: /api/v3/users
method: GET
---

Search within users with email, firstname, lastname.

```attributes
q:
  type: String
  desc: Query string
```

$$$

```response
{
[{
  "id": 137,
  "firstname": "Rick",
  "lastname": "Sanchez"
}]
}
```
