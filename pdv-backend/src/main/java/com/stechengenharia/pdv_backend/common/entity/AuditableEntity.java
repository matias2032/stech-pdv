package com.stechengenharia.pdv_backend.common.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.experimental.SuperBuilder;


import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;
import java.time.Instant;

@MappedSuperclass
@EntityListeners(AuditingEntityListener.class)
@Getter
@Setter
@SuperBuilder 
 @NoArgsConstructor 
 @AllArgsConstructor     

public abstract class AuditableEntity {

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @LastModifiedDate
    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @Column(name = "deleted", nullable = false)
    private boolean deleted = false;

    @Column(name = "sync_status", length = 20, nullable = false)
    private String syncStatus = "PENDING_CREATE"; 

    @Version
    @Column(name = "version", nullable = false)
    private Long version = 1L;

    

    // ==========================================
    // O TRUQUE MÁGICO ESTÁ AQUI:
    // ==========================================
@PreUpdate
public void preUpdate() {
    if ("SYNCED".equals(this.syncStatus)) {  // ← apenas toca se já estava sincronizado
        this.syncStatus = "PENDING_UPDATE";
    }
    // PENDING_CREATE, PENDING_DELETE e PENDING_UPDATE já estão corretos — não tocar
}
}