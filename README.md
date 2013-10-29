# HipaaCrypt Gem [![Code Climate](https://codeclimate.com/repos/526e7d3a7e00a445c300943d/badges/3cb20b99b4a336e33721/gpa.png)](https://codeclimate.com/repos/526e7d3a7e00a445c300943d/feed)

**State:** Prototype *`-(in progress to)>`* Version 1.0.0-stable

## Goal

Provide an encryption library with zero external dependencies. It should be built in pure Ruby and use the
[OpenSSL::Cipher](http://www.ruby-doc.org/stdlib-1.9.3/libdoc/openssl/rdoc/OpenSSL/Cipher.html) library included
in Ruby's Standard Library.

### AttrEncrypted (the old method)
[AttrEncrypted](https://github.com/attr-encrypted/attr_encrypted) was found to have a code climate score of
[![Code Climate](http://allthebadges.io/attr-encrypted/attr_encrypted/code_climate.png)](http://allthebadges.io/attr-encrypted/attr_encrypted/code_climate)
and proved to be a poor implementation of encryption and and overly complex code base. @gerred found that it used all 0s for an initialization
vector. While it seems that future versions have seemed to address this issue, the overal complexity of the
gem has not improved. After discussion with architecture and core product we have devised a plan to wholly
own the method of encryption.

## Functionality

### Encryption [Done]

Encryption should be handled by a wrapper class containing an easy to use DSL over the built in OpenSSL library.
The class dubbed `HipaaCrypt::Encryptor` should be initialized with options used to handle the encryption. At the
very least the requirment is to implement options with a key and cipher (defaulting to aes 256). Further options may
be implemented.

The Encryptor itself must adhere to the following standards:

* it must be initialized with an options hash containing a key.
* it must respond to encrypt, an implementation resulting in the return of an encrypted string.
* it must respond to decrypt, an implementation succesfully able to decrypt a string returned by encrypt.
* encrypt_return_value **must eq** decrypt_input_value
* decrypt_return_value **must eq** encrypt_input_value

### Plain Old Ruby Object (PORO) Attribute Mixins [In Progress]

A module that when included within a ruby object provides methods to assign attributes for encryption.

A sample implementation may look like this:
```ruby
class Poro
  include HippaCrypt::Attributes

  encrypt :foo, :bar,
    key: ENV['ENCRYPTION_KEY'], # required
    cipher: { name: :AES, key_length: 256, mode: :CBC }, # optional
    iv: nil, # optional
    before_encrypt: ->(value){ value.to_s }, # optional
    after_decrypt: ->(value){ value.to_s }, # optional
    prefix: :encrypted_, # optional
    encryptor: HippaCrypt::Encryptor # optional
    
end
```

## ORM Specific Auto Mixins [To Do]

Modules that upon include of the standard mixin will detect the ancestors of the base class and be automatically included.

### ActiveRecord

The active record mixin should provide the following features.

* Rails 3 dynamic finders
  * `find_by_attr_name('foo')`
  * `find_or_initialize_by_attr_name('foo')`
  * `find_or_create_by_attr_name('foo')`
* Rails 4 find_by methods
  * `find_by(attr_name: 'foo')`
  * `find_or_initialize_by(attr_name: 'foo')`
  * `find_or_create_by(attr_name: 'foo')`
* AREL query support
  * `where(attr_name: 'foo')`
  * etc...


## Re-Encryption Support [To Do]

The ability to pass previous options to a `re_encrypt` method, therefor decrypting with the old options and encrypting
with the new.

**example:**

```ruby
irb> Poro.re_encrypt :foo, :bar,
       key: "my old key",
       cipher: { name: :AES, key_length: 256, mode: :CBC }
```

-

***fin***
  
  
