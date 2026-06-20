package com.stechengenharia.pdv_backend.sync;

import com.stechengenharia.pdv_backend.categoria.sync.CategoriaSyncService;
import com.stechengenharia.pdv_backend.cliente.sync.ClienteSyncService;
import com.stechengenharia.pdv_backend.documento.sync.DocumentoSyncService;
import com.stechengenharia.pdv_backend.marca.sync.MarcaSyncService;
import com.stechengenharia.pdv_backend.pedido.sync.PedidoSyncService;
import com.stechengenharia.pdv_backend.produto.sync.ProdutoSyncService;
import com.stechengenharia.pdv_backend.servico.sync.ServicoSyncService;
import com.stechengenharia.pdv_backend.usuario.sync.UsuarioSyncService;
import com.stechengenharia.pdv_backend.cotacao.sync.CotacaoSyncService;
import com.stechengenharia.pdv_backend.fornecedor.sync.FornecedorSyncService;


import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

@Slf4j
@Component
@RequiredArgsConstructor
public class SyncOrchestrator {

    private final UsuarioSyncService usuarioSyncService;
     private final MarcaSyncService marcaSyncService;         // NOVO
    private final CategoriaSyncService categoriaSyncService; 
    private final ProdutoSyncService produtoSyncService;
private final ServicoSyncService servicoSyncService;
private final ClienteSyncService clienteSyncService;
private final DocumentoSyncService documentoSyncService;
private final PedidoSyncService pedidoSyncService;
private final CotacaoSyncService cotacaoSyncService;
private final FornecedorSyncService fornecedorSyncService;

    // private final ClienteSyncService clienteSyncService;
   

    /**
     * Executa a cada 60 segundos.
     * Ordem recomendada: PUSH primeiro (envia o que a loja gerou),
     * depois PULL (recebe actualizações da nuvem ou de outras lojas).
     *
     * Se qualquer módulo falhar, o erro é apanhado DENTRO de cada SyncService.
     * Este método nunca lança excepção, garantindo que o scheduler não para.
     */
    @Scheduled(fixedRate = 60_000)
    public void sincronizar() {
        log.debug("[Orchestrator] Ciclo de sincronização iniciado");

        // ── PUSH (local → nuvem) ──────────────────────────────────────
        usuarioSyncService.push();
        categoriaSyncService.push(); // NOVO
        marcaSyncService.push();   
        produtoSyncService.push();   // PUSH  
        servicoSyncService.push();  // PUSH
        clienteSyncService.push();   // PUSH
        fornecedorSyncService.push();
        documentoSyncService.push(); // PUSH
        pedidoSyncService.push();
        cotacaoSyncService.push();
        
        // clienteSyncService.push();


        // ── PULL (nuvem → local) ──────────────────────────────────────
        usuarioSyncService.pull();
        categoriaSyncService.pull(); // NOVO
        marcaSyncService.pull();  
        produtoSyncService.pull();   // PULL 
        servicoSyncService.pull();   // PULL
        clienteSyncService.pull();
        fornecedorSyncService.pull();
        documentoSyncService.pull(); // PULL
        pedidoSyncService.pull();
        cotacaoSyncService.pull();
        

        log.debug("[Orchestrator] Ciclo de sincronização concluído");
    }
}