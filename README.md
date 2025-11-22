# PalletTrace - Decentralized Asset Tracking System

A Clarity smart contract for tracking pallets, containers, and warehouse equipment across multiple locations on the Stacks blockchain, providing real-time visibility and accountability.

## Features

- **Multi-Location Management**: Track assets across multiple warehouses and facilities
- **Asset Registration**: Register and barcode pallets, containers, and equipment
- **Transfer Tracking**: Record all asset movements between locations
- **Assignment Management**: Assign assets to specific personnel or operations
- **Maintenance Logging**: Track maintenance schedules and service history
- **Capacity Management**: Monitor location capacity and prevent overcrowding

## Contract Functions

### Public Functions
- `register-location(name, location-type, capacity, manager)` - Register new tracking location
- `register-asset(asset-type, barcode, initial-location)` - Register new asset
- `transfer-asset(asset-id, to-location, reason)` - Transfer asset between locations
- `assign-asset(asset-id, assignee)` - Assign asset to user
- `release-asset(asset-id)` - Release asset back to available pool
- `record-maintenance(asset-id, maintenance-type, notes, next-due)` - Log maintenance activity

### Read-only Functions
- `get-asset(asset-id)` - Get complete asset details and current status
- `get-location(location-id)` - Get location information and capacity
- `is-location-full(location-id)` - Check if location is at capacity
- `is-asset-available(asset-id)` - Verify asset availability

## Asset Types

Supported asset types include:
- `PALLET` - Standard shipping pallets
- `CONTAINER` - Storage containers
- `FORKLIFT` - Material handling equipment
- `DOLLY` - Transport dollies
- `CAGE` - Security cages

## Status Values

Asset status options:
- `AVAILABLE` - Ready for assignment
- `ASSIGNED` - Currently assigned to user
- `MAINTENANCE` - Under maintenance
- `DAMAGED` - Requires repair

## Usage

Register locations first, then add assets with barcodes. Track asset movements, assignments, and maintenance throughout their lifecycle. All movements create immutable audit trails.

## Development

Built with Clarity for the Stacks blockchain. Designed for integration with barcode scanners and RFID systems for automated tracking.