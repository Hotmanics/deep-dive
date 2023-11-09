// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

// import { console2 } from "forge-std/Test.sol"; // remove before deploy
import {HatsModule, HatsEligibilityModule} from "hats-module/HatsEligibilityModule.sol";
import {IGitcoinResolver} from "eas-proxy/IGitcoinResolver.sol";
import {Attestation} from "eas-contracts/Common.sol";
import {EAS} from "./EAS.sol";

contract Module is HatsEligibilityModule {
    bytes32 public constant SCORE_SCHEMA =
        0x6ab5d34260fca0cfcf0e76e96d439cace6aa7c3c019d7c4580ed52c6845e9c89;

    IGitcoinResolver public constant GITCOIN_RESOLVER =
        IGitcoinResolver(0x6dd0CB3C3711c8B5d03b3790e5339Bbc2Bbcf934);

    uint256 public constant SCORE_THRESHOLD = 20;

    EAS public constant eas = EAS(0x0000000000000000000000000000000000000000);

    /*//////////////////////////////////////////////////////////////
                            CUSTOM ERRORS
  //////////////////////////////////////////////////////////////*/

    /*//////////////////////////////////////////////////////////////
                              EVENTS
  //////////////////////////////////////////////////////////////*/

    /*//////////////////////////////////////////////////////////////
                            DATA MODELS
  //////////////////////////////////////////////////////////////*/

    /*//////////////////////////////////////////////////////////////
                            CONSTANTS 
  //////////////////////////////////////////////////////////////*/

    /**
     * This contract is a clone with immutable args, which means that it is deployed with a set of
     * immutable storage variables (ie constants). Accessing these constants is cheaper than accessing
     * regular storage variables (such as those set on initialization of a typical EIP-1167 clone),
     * but requires a slightly different approach since they are read from calldata instead of storage.
     *
     * Below is a table of constants and their location.
     *
     * For more, see here: https://github.com/Saw-mon-and-Natalie/clones-with-immutable-args
     *
     * ----------------------------------------------------------------------+
     * CLONE IMMUTABLE "STORAGE"                                             |
     * ----------------------------------------------------------------------|
     * Offset  | Constant          | Type    | Length  | Source              |
     * ----------------------------------------------------------------------|
     * 0       | IMPLEMENTATION    | address | 20      | HatsModule          |
     * 20      | HATS              | address | 20      | HatsModule          |
     * 40      | hatId             | uint256 | 32      | HatsModule          |
     * 72+     | {other constants} | address | -       | {this}              |
     * ----------------------------------------------------------------------+
     */

    /*//////////////////////////////////////////////////////////////
                            MUTABLE STATE
  //////////////////////////////////////////////////////////////*/

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
  //////////////////////////////////////////////////////////////*/

    /// @notice Deploy the implementation contract and set its version
    /// @dev This is only used to deploy the implementation contract, and should not be used to deploy clones
    constructor(string memory _version) HatsModule(_version) {}

    /*//////////////////////////////////////////////////////////////
                            INITIALIZOR
  //////////////////////////////////////////////////////////////*/

    /// @inheritdoc HatsModule
    function _setUp(bytes calldata _initData) internal override {
        // decode init data
    }

    function getWearerStatus(
        address _wearer,
        uint256 _hatId
    ) public view override returns (bool eligible, bool standing) {
        eligible = _getScore(_wearer) >= SCORE_THRESHOLD;
        standing = true;
        return (eligible, standing);
    }

    function getUserAttestation(
        address user,
        bytes32 schema
    ) external view returns (bytes32) {}

    function _getScore(address wearer) internal view returns (uint256 score) {
        bytes32 attestationUID = GITCOIN_RESOLVER.getUserAttestation(
            wearer,
            SCORE_SCHEMA
        );

        if (attestationUID == 0) return 0;

        Attestation memory attestation = eas.getAttestation(attestationUID);

        if (attestation.revocationTime > 0) return 0;

        if (
            attestation.expirationTime > 0 &&
            attestation.expirationTime <= block.timestamp
        ) return 0;

        (score, , ) = abi.decode(attestation.data, (uint256, uint256, uint256));
    }

    /*//////////////////////////////////////////////////////////////
                        PUBLIC FUNCTIONS
  //////////////////////////////////////////////////////////////*/

    /*//////////////////////////////////////////////////////////////
                          VIEW FUNCTIONS
  //////////////////////////////////////////////////////////////*/

    /*//////////////////////////////////////////////////////////////
                        INTERNAL FUNCTIONS
  //////////////////////////////////////////////////////////////*/

    /*//////////////////////////////////////////////////////////////
                            MODIFERS
  //////////////////////////////////////////////////////////////*/
}
