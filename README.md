# HipaaCrypt Gem

## Goal

Provide a universal wrapper for encrypting data in plain old ruby objects.

# Examples

```ruby
encrypt :foo,
  attr: :encrypted_foo, # implicit
  encryptor: HippaCrypt::Encryptor # implicit
  
```
  
