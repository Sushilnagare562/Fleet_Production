package com.logisticfleet.repository;

import com.logisticfleet.entity.DriverStatus;
import com.logisticfleet.entity.Role;
import com.logisticfleet.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByEmail(String email);
    Optional<User> findByPhone(String phone);
    boolean existsByEmail(String email);
    boolean existsByPhone(String phone);
    List<User> findByRole(Role role);
    List<User> findByTenantIdAndRole(Long tenantId, Role role);
    Optional<User> findByIdAndTenantId(Long id, Long tenantId);

    /** Powers the admin driver list - soft-deleted drivers stay in the DB but never show up here. */
    List<User> findByTenantIdAndRoleAndDriverStatusNot(Long tenantId, Role role, DriverStatus excludedStatus);
}
