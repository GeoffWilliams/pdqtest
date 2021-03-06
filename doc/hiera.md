# Hiera
Under normal circumstances, only a `profile` module would be consuming Hiera 
data directly using the `lookup()` function, and its suggested by Puppet that 
most of these fall back to automatic data binding parameters rather then using
the function directly.  

In this case it makes more sense to use the excellent 
[Onceover](https://github.com/dylanratcliffe/onceover) tool to perform 
end-to-end testing of your Hiera data, puppet control repository and 
roles/profile modules.

That said, there may be occasions where you need to mock hiera data:
* You have implemented Roles and Profiles as a namespace inside a team module 
  (for multi-tenanting)
* You have a module that performs `lookup()` lookups directly
* You intend to drive your module by adding data to hiera and including a class
  to make something happen
* Your class fails to compile due to missing hiera data
* You have a separate git repository for your `profile` module and want to be 
  able to test it

## Alternative method
In most cases it may be easiest to directly inject strings in lieu of setting up
a fake hiera:

### RSpec Tests
```ruby
let :params do
  {
    :data_from_hiera => "faked by",
    :more_data       => "hardcoding inline",
  }
end
```

### Acceptance tests
```puppet
class { "foo":
  data_from_hiera => "faked by",
  more_data       => "hardcoding inline",
}
```

Note that you would need to duplicate your hard-coded mock data between the 
rspec tests and any acceptance tests.

In the more complex cases it may instead be desirable to mock the hiera data in
order to enable Puppet's regular lookup systems to work.

## Mocking Hiera (RSpec tests)
PDQTest fully delegates RSpec tests to PDK, so see 
[RSpec docs](https://rspec-puppet.com/documentation/configuration/) for how to
do this.

## Mocking hiera (Acceptance tests)
PDQTest supports full mocking of Hiera acceptance tests and support for this is
enabled automatically when `pdqtest init` is run.

A basic one-level hierachy is created for you:
* Hiera configuration file at `spec/fixtures/hiera.yaml`
* Single hiera data file at `spec/fixtures/hieradata/test.yaml`

Any required hiera data can be added to `test.yaml` and will immediately show up
when lookups are made.
