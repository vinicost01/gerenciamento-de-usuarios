# NovaLink - Sistema de Gerenciamento de Usuários

Este projeto é uma solução completa para gerenciamento de usuários, desenvolvido como um trabalho acadêmico. O sistema é composto por uma **API Robusta em .NET 8** e um **Aplicativo Multiplataforma em Flutter**.

O objetivo principal é fornecer uma plataforma segura para administração de usuários, com controle de acesso baseado em cargos (Admin/User), fluxos de autenticação seguros e notificações automáticas por email.

## 🚀 Tecnologias Utilizadas

### Backend (AuthApi)
*   **Framework:** .NET 8 (C#)
*   **Banco de Dados:** MySQL (via Entity Framework Core com Pomelo)
*   **Autenticação:** JWT (JSON Web Tokens)
*   **Segurança:** BCrypt para hashing de senhas
*   **Email:** SMTP (`System.Net.Mail`)
*   **Containerização:** Docker & Docker Compose
*   **Proxy Reverso:** Caddy Server

### Frontend (NovaLinkApp)
*   **Framework:** Flutter (Dart)
*   **Plataformas Suportadas:** Android, iOS, Web, Windows, macOS, Linux
*   **Gerenciamento de Estado:** Provider (inferido)
*   **UI/UX:** Material Design

---

## 🛠 Funcionalidades

### 📱 Aplicativo (App)
O aplicativo serve como a interface para usuários finais e administradores interagirem com o sistema.

*   **Login Seguro:** Autenticação via credenciais (Email/Username e Senha).
*   **Perfil do Usuário:** Visualização e edição de dados pessoais (Nome, Telefone, Escritório, Foto de Perfil).
*   **Recuperação de Senha:** Fluxo completo de "Esqueci minha senha" com código de verificação enviado por email.
*   **Alteração Obrigatória de Senha:** O sistema força a troca de senha no primeiro acesso para usuários recém-criados.
*   **Painel Administrativo (Exclusivo para Admins):**
    *   Listagem completa de usuários.
    *   Cadastro de novos usuários com geração automática de credenciais.
    *   Edição de dados de outros usuários.
    *   Exclusão de contas.

### 🌐 API (Backend)
A API RESTful gerencia toda a lógica de negócios, segurança e persistência de dados.

#### 📧 Serviço de Email (EmailService)
Uma das funcionalidades centrais do projeto é o sistema de notificações automáticas via SMTP.

1.  **Email de Boas-Vindas (Criação de Conta):**
    *   **Gatilho:** Quando um Admin cria um novo usuário na rota `POST /api/Users`.
    *   **Conteúdo:** Envia um email HTML formatado contendo o **Nome**, **Username** e uma **Senha Provisória**.
    *   **Objetivo:** Permitir que o novo usuário acesse o sistema imediatamente.

2.  **Email de Recuperação de Senha:**
    *   **Gatilho:** Quando um usuário solicita recuperação na rota `POST /api/Auth/forgot-password`.
    *   **Conteúdo:** Envia um código numérico de 6 dígitos (Token).
    *   **Segurança:** O código expira automaticamente em 30 minutos.

---

## 📚 Documentação da API

Abaixo estão os principais endpoints disponíveis na API.

### Autenticação (`/api/Auth`)
| Método | Endpoint | Descrição |
| :--- | :--- | :--- |
| `POST` | `/login` | Autentica o usuário e retorna o Token JWT. |
| `POST` | `/change-initial-password` | Altera a senha provisória (Obrigatório no 1º acesso). |
| `POST` | `/forgot-password` | Envia o código de recuperação por email. |
| `POST` | `/reset-password` | Redefine a senha usando o código recebido. |

### Gerenciamento de Usuários (`/api/Users`)
*Todos os endpoints abaixo requerem autenticação (Token Bearer).*

| Método | Endpoint | Acesso | Descrição |
| :--- | :--- | :--- | :--- |
| `GET` | `/` | **Admin** | Lista todos os usuários cadastrados. |
| `POST` | `/` | **Admin** | Cria um novo usuário e envia email de boas-vindas. |
| `PUT` | `/{id}` | **Admin** | Atualiza os dados de um usuário específico. |
| `DELETE`| `/{id}` | **Admin** | Remove um usuário do sistema. |
| `PUT` | `/me` | **Todos** | Atualiza o perfil do próprio usuário logado. |

---

## 🔧 Como Executar o Projeto

### Pré-requisitos
*   Docker & Docker Compose
*   Flutter SDK (para rodar o app localmente)
*   .NET SDK (caso queira rodar a API fora do Docker)

### Executando a API (Docker)
O projeto já conta com orquestração via Docker Compose, incluindo um servidor Caddy como proxy reverso.

1.  Navegue até a pasta da API:
    ```bash
    cd AuthApi
    ```
2.  Configure o arquivo `appsettings.json` (ou variáveis de ambiente) com as credenciais do seu servidor SMTP (Email).
3.  Suba os containers:
    ```bash
    docker-compose up -d --build
    ```
    *A API estará acessível via `http://localhost` (proxy) ou porta configurada.*

### Executando o App (Flutter)
1.  Navegue até a pasta do aplicativo:
    ```bash
    cd novalinkapp
    ```
2.  Instale as dependências:
    ```bash
    flutter pub get
    ```
3.  Execute o projeto:
    ```bash
    flutter run
    ```

---

## Link para uma pasta com o video do app funcionando e outros arquivos relevantes

https://drive.google.com/drive/folders/1IoxI8mDRnF7AxAKopJjmnn4oQuKpcBHw?usp=sharing




## 👥 Autores

Projeto desenvolvido como parte de um trabalho acadêmico.

*   **Vinicius Augusto Moreira Costa** (Desenvolvedor)
