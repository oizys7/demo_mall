package com.oizys.mall.order.entity;

import jakarta.persistence.*;
import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@Entity
@Table(name = "oms_order")
public class Order {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    private String orderSn;
    
    private Long userId;
    
    private BigDecimal totalAmount;
    
    private Integer status;
    
    private String receiverName;
    
    private String receiverPhone;
    
    private String receiverAddress;
    
    private LocalDateTime createTime;
    
    private LocalDateTime updateTime;
}