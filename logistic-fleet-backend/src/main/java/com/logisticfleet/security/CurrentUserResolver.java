package com.logisticfleet.security;

import com.logisticfleet.entity.User;
import com.logisticfleet.exception.ResourceNotFoundException;
import com.logisticfleet.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

/**
 * Resolves the currently authenticated User (from the JWT-backed SecurityContext)
 * so controllers can act on behalf of "me" instead of trusting a client-supplied id.
 */
@Component
@RequiredArgsConstructor
public class CurrentUserResolver {

    private final UserRepository userRepository;

    public User getCurrentUser() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        String email = auth.getName();
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("Authenticated user not found: " + email));
    }

    public Long getCurrentUserId() {
        return getCurrentUser().getId();
    }

    /**
     * The tenant (company) the currently authenticated user belongs to.
     * Every "list all" / report endpoint must filter through this so one
     * company can never see another company's data.
     */
    @Transactional(readOnly = true)
    public Long getCurrentTenantId() {
        return getCurrentUser().getTenant().getId();
    }
}