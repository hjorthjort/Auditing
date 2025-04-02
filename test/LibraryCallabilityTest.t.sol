// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";

// We define a new struct datatype that will be used to
// hold its data in the calling contract.
struct Data {
    mapping(uint => bool) flags;
}

library Set {
    // Note that the first parameter is of type "storage
    // reference" and thus only its storage address and not
    // its contents is passed as part of the call.  This is a
    // special feature of library functions.  It is idiomatic
    // to call the first parameter `self`, if the function can
    // be seen as a method of that object.
    function insert(Data storage self, uint value)
        public
        returns (bool)
    {
        if (self.flags[value])
            return false; // already there
        self.flags[value] = true;
        return true;
    }

    function remove(Data storage self, uint value)
        public
        returns (bool)
    {
        if (!self.flags[value])
            return false; // not there
        self.flags[value] = false;
        return true;
    }

    function contains(Data storage self, uint value)
        public
        view
        returns (bool)
    {
        return self.flags[value];
    }
    
    event Foo();

    function foo(Data storage) public {
      emit Foo();
    }
}

interface IC {
  function register(uint value) external;
  function foo() external;

}

contract C {
    Data knownValues;

    function register(uint value) public {
        // The library functions can be called without a
        // specific instance of the library, since the
        // "instance" will be the current contract.
        require(Set.insert(knownValues, value));
    }

    /* Uncomment to make test fail.
    // In this contract, we can also directly access knownValues.flags, if we want.
    function foo() public {
        Set.foo(knownValues);
    }
    */
}


contract LibraryExposesCallsTest is Test {
    // Try calling a C instance, see if we can call the `foo` function on it even if it's not exposed.
    // This should compile, because we are casting it to an interfact that exposes foo().
  function testCallLib() public {
    IC c = IC(address(new C()));

    vm.expectRevert();
    c.foo();
  }
}
