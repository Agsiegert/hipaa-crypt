# HipaaCrypt Gem

## Goal

Provide a universal wrapper for encrypting data in plain old ruby objects.

# Steps
The steps to encryption will be as follows, an encrypted object will always be marshalized.

## Encrypt

1. Initializer encryptor `HippaCrypt::Encryptor.new(options).encrypt(value)`.
2. Encryptor generates or uses a provided iv, encrypts the value with the specified key and returns a Encoded and
  Marshaled `EncryptedObject` containing an `@iv` and `@encrypted_value`.
3. The writer takes the returned string and writes it to 

# Examples

## Encrypted Attributes Mixin

Encrypted attributes will use alias methods to handle the encryption assignment, there is no need to change
database tables to support custom attributes for encryption, this is accomplished in pure ruby.

ex: by setting :foo to encrypt, then :foo will become :encrypted_foo, and :foo will will use the encryptor.

```ruby
class Poro
  include HippaCrypt::Attributes

  encrypt :foo,
    cipher: { name: :AES, key_length: 256, mode: :CBC }, # required
    key: ENV['ENCRYPTION_KEY'], # required
    iv: nil, # optional
    before_encrypt: ->(value){ value.to_s }, # optional
    after_decrypt: ->(value){ value.to_s }, # optional
    prefix: :encrypted_, # optional
    encryptor: HippaCrypt::Encryptor # optional
    
end
```
  
