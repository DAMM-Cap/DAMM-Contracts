// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

interface IModuleFactory {
    function deployContract(bytes32 salt, uint256 value, bytes memory creationCode)
        external
        returns (address contractAddress);

    function deployModule(bytes32 salt, uint256 value, bytes memory creationCode)
        external
        returns (address module);

    function deployModuleWithRoles(
        bytes32 salt,
        uint256 value,
        bytes memory creationCode,
        uint256 roles
    ) external returns (address module);

    function addModule(address module) external;

    function addModuleWithRoles(address module, uint256 roles) external;

    function computeAddress(bytes32 salt, bytes32 bytecodeHash, address deployer)
        external
        pure
        returns (address addr);
}
