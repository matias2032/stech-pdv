package com.stechengenharia.pdv_backend.usuario.sync;

import com.stechengenharia.pdv_backend.usuario.entity.Usuario;
import com.stechengenharia.pdv_backend.usuario.repository.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.RestTemplate;

import java.time.OffsetDateTime;
import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class UsuarioSyncService {

    private final UsuarioRepository usuarioRepository;
    private final RestTemplate      restTemplate;

    @Value("${sync.cloud.base-url}")          // ex: https://api.meuservidor.com
    private String cloudBaseUrl;

    @Value("${sync.cloud.api-key}")           // chave secreta partilhada
    private String apiKey;

    // ── PUSH: Local → Nuvem ───────────────────────────────────────────

    /**
     * Envia todos os registos pendentes para a nuvem.
     * Tolerante a falhas: qualquer excepção é apanhada e logada.
     * O registo fica PENDING e será tentado novamente no próximo ciclo.
     */
    @Transactional
    public void push() {
        List<Usuario> pendentes = usuarioRepository.findBySyncStatusIn(
                List.of("PENDING_CREATE", "PENDING_UPDATE", "PENDING_DELETE"));

        if (pendentes.isEmpty()) return;

        log.info("[UsuarioSync] PUSH → {} registos pendentes", pendentes.size());

        List<UsuarioSyncDTO> payload = pendentes.stream()
                .map(UsuarioSyncDTO::from)
                .toList();

        try {
            ResponseEntity<Void> response = restTemplate.exchange(
                    cloudBaseUrl + "/sync/usuarios",
                    HttpMethod.POST,
                    new HttpEntity<>(payload, buildHeaders()),
                    Void.class
            );

            if (response.getStatusCode().is2xxSuccessful()) {
                List<Long> ids = pendentes.stream().map(Usuario::getId).toList();
                usuarioRepository.markAsSynced(ids);
                log.info("[UsuarioSync] PUSH ✓ {} registos marcados como SYNCED", ids.size());
            } else {
                log.warn("[UsuarioSync] PUSH ✗ Nuvem respondeu {}", response.getStatusCode());
            }

        } catch (Exception e) {
            // Falha de rede, timeout, 5xx — falha silenciosa, próximo ciclo tentará de novo
            log.warn("[UsuarioSync] PUSH ✗ Falha de comunicação: {}", e.getMessage());
        }
    }

    // ── PULL: Nuvem → Local ───────────────────────────────────────────

    /**
     * Busca da nuvem os registos modificados após a última sincronização bem-sucedida.
     * Usa o campo updated_at do registo mais recente como cursor.
     */
@Transactional
public void pull() {
    // Cursor: data do registo local mais recentemente atualizado
    OffsetDateTime cursor = usuarioRepository
            .findAll()
            .stream()
            .map(u -> u.getUpdatedAt())
            .filter(java.util.Objects::nonNull)              // Evita NullPointerException se houver registos sem data
            .max(java.time.Instant::compareTo)               // 🟢 Usa o comparador correto para Instant
            .map(instant -> OffsetDateTime.ofInstant(instant, java.time.ZoneOffset.UTC)) // 🟢 Converte o maior Instant encontrado para OffsetDateTime
            .orElse(OffsetDateTime.parse("2000-01-01T00:00:00Z"));

    log.info("[UsuarioSync] PULL → buscando registos após {}", cursor);

        try {
            ResponseEntity<List<UsuarioSyncDTO>> response = restTemplate.exchange(
                    cloudBaseUrl + "/sync/usuarios?since=" + cursor,
                    HttpMethod.GET,
                    new HttpEntity<>(buildHeaders()),
                    new ParameterizedTypeReference<>() {}
            );

            if (!response.getStatusCode().is2xxSuccessful()
                    || response.getBody() == null
                    || response.getBody().isEmpty()) {
                return;
            }

            List<UsuarioSyncDTO> atualizados = response.getBody();
            log.info("[UsuarioSync] PULL ✓ {} registos recebidos da nuvem", atualizados.size());

            for (UsuarioSyncDTO dto : atualizados) {
                aplicarAtualizacaoLocal(dto);
            }

        } catch (Exception e) {
            log.warn("[UsuarioSync] PULL ✗ Falha de comunicação: {}", e.getMessage());
        }
    }

    // ── HELPERS ───────────────────────────────────────────────────────

    private void aplicarAtualizacaoLocal(UsuarioSyncDTO dto) {
        // Busca pelo ID de nuvem (campo cloud_id no DTO) para evitar duplicados
        usuarioRepository.findByIdComPerfil(dto.localId()).ifPresentOrElse(
                existente -> {
                    // Só aplica se a versão da nuvem for mais recente
                    if (dto.version() > existente.getVersion()) {
                        existente.setNome(dto.nome());
                        existente.setAtivo(dto.ativo());
                        existente.setDeleted(dto.deleted());
                        existente.setSyncStatus("SYNCED");
                        existente.setVersion(dto.version());
                        usuarioRepository.save(existente);
                    }
                },
                () -> log.debug("[UsuarioSync] PULL — registo {} não existe localmente, ignorado", dto.localId())
        );
    }

    private HttpHeaders buildHeaders() {
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.set("X-Sync-Api-Key", apiKey); // autenticação simples entre sistemas
        return headers;
    }
}