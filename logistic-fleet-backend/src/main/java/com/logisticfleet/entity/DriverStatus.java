package com.logisticfleet.entity;

/**
 * Admin-facing driver lifecycle state, separate from the generic
 * {@link User#isActive()} login-disable flag so it can express more than
 * just on/off.
 * <p>
 * DELETED is a soft delete - the row (and all its trip/expense/earning
 * history) is kept, but the driver is filtered out of the admin driver
 * list and can no longer log in.
 */
public enum DriverStatus {
    ACTIVE, ON_LEAVE, DELETED
}
