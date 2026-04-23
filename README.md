# customer-service-vb6

Legacy VB6 COM+ service for Customer Management.

This repo exists as a realistic POC target for the [ccs-code](https://github.com/eminbayrak/ccs-code) migration tooling. It demonstrates the tool's ability to handle:
- **Legacy Languages**: VB6/COM+ (`.cls`, `.vbp`)
- **Idiomatic Logic**: `On Error GoTo`, `ADODB.Recordset`, `XML` string building
- **Complex Business Rules**: Hidden in legacy code (Deactivated account guards, Tier-based clearance)

---

## Services

### CustomerManager

| Operation | Description |
|-----------|-------------|
| `GetCustomer` | Returns customer profile as XML. Enforces security guards. |
| `UpdateProfile` | Updates email with corporate domain validation. |

**Key business rules discovered in source:**
- **Deactivated Guard**: Deactivated accounts are invisible to standard users (`Status = "Deactivated"`).
- **VIP Clearance**: Customers with `Tier = "VIP"` require `Tier-1` clearance in the session token.
- **Email Validation**: Corporate accounts require specific domain validation (implied in logic).

---

## Database

| Database | Tables | Description |
|----------|--------|-------------|
| Customers | `Customers` | ID, Name, Email, Tier, Status, CreditLimit |

---

## Structure

```
CustomerService/
  CustomerManager.cls    — VB6 Class implementation
  CustomerService.vbp    — VB6 Project file
```

---

## Running with ccs-code

```
/migrate scan --repo https://github.com/eminbayrak/node-orders-api --lang csharp --yes
```

The scanner will find calls to `CustomerManager` in the Node.js app, resolve it to this repo, and analyze the VB6 source to extract the business rules for migration to a modern .NET/Node service.
