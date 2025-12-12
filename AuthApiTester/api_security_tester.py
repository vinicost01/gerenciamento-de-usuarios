import requests
import json
import time
import random
import string

class Cores:
    VERDE = '\033[92m'
    AMARELO = '\033[93m'
    VERMELHO = '\033[91m'
    RESET = '\033[0m'
    AZUL = '\033[94m'
    MAGENTA = '\033[95m'
    CIANO = '\033[96m'
    CINZA = '\033[90m'

def print_info(mensagem): print(f"{Cores.AZUL}[INFO] {mensagem}{Cores.RESET}")
def print_sucesso(mensagem): print(f"{Cores.VERDE}[SUCESSO] {mensagem}{Cores.RESET}")
def print_falha(mensagem): print(f"{Cores.VERMELHO}[FALHA] {mensagem}{Cores.RESET}")
def print_aviso(mensagem): print(f"{Cores.AMARELO}[AVISO] {mensagem}{Cores.RESET}")
def print_etapa_header(texto): print(f"\n{Cores.MAGENTA}{'='*25} [ {texto} ] {'='*25}{Cores.RESET}")
def print_endpoint_header(texto): print(f"\n{Cores.CIANO}--- TESTANDO {texto} ---{Cores.RESET}")

def print_request_details(method, endpoint, headers, json_body):
    print(f"{Cores.CINZA}  -> Request: {method.upper()} {BASE_URL}{endpoint}{Cores.RESET}")
    if headers and "Authorization" in headers: print(f"{Cores.CINZA}  -> Auth: Bearer token (ocultado){Cores.RESET}")
    if json_body:
        payload_str = json.dumps(json_body, indent=2)
        colored_payload = "\n".join([f"{Cores.CINZA}     {line}{Cores.RESET}" for line in payload_str.split('\n')])
        print(f"{Cores.CINZA}  -> Payload:{Cores.RESET}\n{colored_payload}")

def print_response_details(response, display_body=True):
    if not response:
        print_falha("  <- Response: Nenhuma resposta recebida (erro de conexão).")
        return
    status_code = response.status_code
    is_success = 200 <= status_code < 300
    status_color = Cores.VERDE if is_success else Cores.VERMELHO
    print(f"  <- Response: {status_color}{status_code}{Cores.RESET}")
    if not display_body: return
    body_color = Cores.CINZA if is_success else Cores.VERMELHO
    try:
        body_str = json.dumps(response.json(), indent=2, ensure_ascii=False)
        colored_body = "\n".join([f"{body_color}       {line}{Cores.RESET}" for line in body_str.split('\n')])
        print(f"{body_color}     Body:\n{colored_body}{Cores.RESET}")
    except (json.JSONDecodeError, AttributeError):
        if response.text: print(f"{body_color}     Body: {response.text[:300]}...{Cores.RESET}")

BASE_URL = "http://localhost:5000" 
ADMIN_USERNAME = "testuser"
ADMIN_PASSWORD = "abcdef123!"

test_state = {"auth_token": None, "new_user_id": None}
test_summary = {
    "functional": {"passed": 0, "failed": 0, "executed": []},
    "security": {"vulnerabilities": 0}
}
SECURITY_PAYLOADS = {"SQLi": "' OR 1=1; --", "XSS": "<script>alert('xss')</script>"}

def fazer_requisicao(method, endpoint, headers=None, json_body=None, display_body=True):
    print_request_details(method, endpoint, headers, json_body)
    url = BASE_URL + endpoint
    try:
        response = requests.request(method.upper(), url, headers=headers, json=json_body, timeout=15, verify=False)
    except requests.exceptions.RequestException as e:
        response, url = None, str(e)
    print_response_details(response, display_body)
    return response

def get_auth_header():
    if not test_state["auth_token"]: return None
    return {"Content-Type": "application/json", "Authorization": f"Bearer {test_state['auth_token']}"}

def generate_strong_password():
    chars = string.ascii_letters + string.digits + string.punctuation
    password = ''.join(random.choice(string.digits) for i in range(3)) + random.choice(string.punctuation)
    while len(password) < 12: password += random.choice(chars)
    return ''.join(random.sample(password, len(password)))


def run_injection_tests(method, endpoint, headers, json_body):
    print_info("--- Iniciando Testes de Injeção ---")
    for test_name, payload in SECURITY_PAYLOADS.items():
        if not json_body: continue
        for key in json_body:
            injected_body = json_body.copy()
            injected_body[key] = str(injected_body.get(key, "")) + payload
            res = fazer_requisicao(method, endpoint, headers, json_body=injected_body, display_body=False)
            if res and res.status_code == 500:
                print_falha(f"  -> {test_name}: Possível vulnerabilidade no campo '{key}'. API retornou 500.")
                test_summary["security"]["vulnerabilities"] += 1


def test_login():
    print_endpoint_header("POST /api/Auth/login")
    if not ADMIN_PASSWORD:
        print_falha("Senha do admin (ADMIN_PASSWORD) não configurada."); return False
    payload = {"identifier": ADMIN_USERNAME, "password": ADMIN_PASSWORD}
    res = fazer_requisicao("POST", "/api/Auth/login", {"Content-Type": "application/json"}, json_body=payload)
    if res and res.status_code == 200 and "accessToken" in res.json():
        test_state["auth_token"] = res.json()["accessToken"]; print_sucesso("Token de admin armazenado."); return True
    return False

def test_create_user():
    print_endpoint_header("POST /api/Users")
    headers = get_auth_header()
    if not headers: return False
    timestamp = int(time.time())
    payload = {
        "username": f"newuser_{timestamp}", "nome": "Novo Usuario Teste", "email": f"newuser_{timestamp}@test.com",
        "password": generate_strong_password(), "role": "user", "phone": "11999998888",
        "cod_assessor": "a1234", "escritorio": "teste"
    }
    res = fazer_requisicao("POST", "/api/Users", headers, json_body=payload)
    if res and res.status_code == 201 and "id" in res.json():
        test_state["new_user_id"] = res.json()["id"]; print_sucesso(f"ID do novo usuário ({res.json()['id']}) armazenado.")
        run_injection_tests("POST", "/api/Users", headers, payload)
        return True
    return False

def test_list_users():
    print_endpoint_header("GET /api/Users")
    headers = get_auth_header()
    if not headers: return False
    res = fazer_requisicao("GET", "/api/Users", headers, display_body=False)
    if res and res.status_code == 200:
        users = res.json(); print_sucesso(f"API retornou {len(users)} usuários. Exibindo ID e Nome:")
        for user in users: print(f"{Cores.CINZA}  - ID: {user.get('id', 'N/A')}, Nome: {user.get('nome', 'N/A')}{Cores.RESET}")
        return True
    return False

def test_update_user():
    print_endpoint_header("PUT /api/Users/{id}")
    headers = get_auth_header()
    user_id = test_state.get("new_user_id")
    if not headers or not user_id: return False
    payload = {
        "username": f"updated_{int(time.time())}", "nome": "Nome do Usuario Atualizado",
        "email": f"updated_{int(time.time())}@test.com", "role": "user", "escritorio": "escritorio atualizado"
    }
    res = fazer_requisicao("PUT", f"/api/Users/{user_id}", headers, json_body=payload)
    if res and res.status_code == 200:
        run_injection_tests("PUT", f"/api/Users/{user_id}", headers, payload)
        return True
    return False

def test_delete_user():
    print_endpoint_header("DELETE /api/Users/{id}")
    headers = get_auth_header()
    user_id = test_state.get("new_user_id")
    if not headers or not user_id: return False
    res = fazer_requisicao("DELETE", f"/api/Users/{user_id}", headers, display_body=False)
    if res and res.status_code == 204:
        print_sucesso(f"Usuário de teste com ID {user_id} deletado."); return True
    return False

def print_final_summary():
    print_etapa_header("RESUMO FINAL DA EXECUÇÃO")
    passed = test_summary['functional']['passed']; failed = test_summary['functional']['failed']
    executed = test_summary['functional']['executed']
    
    print_info(f"Testes Funcionais: {len(executed)} executados ({passed} passaram, {failed} falharam).")
    for test_name in executed:
        print(f"{Cores.CINZA}  - {test_name}{Cores.RESET}")

    if failed > 0: print_falha("  -> Verifique os logs para entender as falhas nas requisições.")
    else: print_sucesso("  -> Todos os testes de requisição executados passaram.")

    vulns = test_summary['security']['vulnerabilities']
    print_info(f"Testes de Segurança: {vulns} vulnerabilidades potenciais encontradas.")
    if vulns > 0: print_falha("  -> Vulnerabilidades de injeção podem existir. A API retornou erro 500.")
    else: print_sucesso("  -> Nenhum teste de injeção retornou erro 500.")

def main():
    print(f"{Cores.MAGENTA}{'='*60}\n      INICIANDO SUITE DE TESTES DE API\n{'='*60}{Cores.RESET}")
    if not BASE_URL:
        print_falha("A variável 'BASE_URL' não está configurada. Encerrando."); return
    
    functional_tests = {
        "Login": test_login, "Criar Usuário": test_create_user, "Listar Usuários": test_list_users,
        "Atualizar Usuário": test_update_user, "Deletar Usuário": test_delete_user
    }

    def run_test(test_name):
        test_summary['functional']['executed'].append(test_name)
        if functional_tests[test_name]():
            test_summary['functional']['passed'] += 1
            return True
        else:
            test_summary['functional']['failed'] += 1
            return False

  
    print_etapa_header("ETAPA 1: AUTENTICAÇÃO")
    if not run_test("Login"):
        print_falha("Login falhou. Abortando."); print_final_summary(); return


    print_etapa_header("ETAPA 2: TESTES DE FUNCIONALIDADE")
    if run_test("Criar Usuário"):
        run_test("Listar Usuários")
        run_test("Atualizar Usuário")
    else: print_aviso("Criação de usuário falhou, testes dependentes foram pulados.")

 
    print_etapa_header("ETAPA FINAL: LIMPEZA E VERIFICAÇÃO")
    if not test_state["new_user_id"]: print_info("Nenhum usuário de teste foi criado, limpeza não necessária.")
    else:
        if run_test("Deletar Usuário"):
            print_info("Verificando a lista de usuários após a exclusão...")
            run_test("Listar Usuários")
    
    print_final_summary()
    print(f"\n{Cores.MAGENTA}{'='*60}\n                 SUITE DE TESTES FINALIZADA\n{'='*60}{Cores.RESET}")

if __name__ == "__main__":
    requests.packages.urllib3.disable_warnings(requests.packages.urllib3.exceptions.InsecureRequestWarning)
    main()
