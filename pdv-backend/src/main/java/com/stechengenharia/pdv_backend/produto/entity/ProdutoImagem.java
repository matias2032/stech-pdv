package com.stechengenharia.pdv_backend.produto.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "produto_imagem")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ProdutoImagem {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_imagem")
    private Integer idImagem;
    
    @Column(name = "id_produto", nullable = false)
    private Integer idProduto;
    
    @Column(name = "caminho_imagem", nullable = false, length = 255)
    private String caminhoImagem;
    
    @Column(name = "legenda", columnDefinition = "TEXT")
    private String legenda;
    
    // ✅ MUDANÇA: Integer → Short
    @Column(name = "imagem_principal", nullable = false)
    private Short imagemPrincipal = 0; // 0 = não, 1 = sim
}