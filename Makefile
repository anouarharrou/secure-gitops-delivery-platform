.PHONY: check start cluster platform policies root-app verify port-forwards admission-tests clean

check:
	./scripts/check-prereqs.sh

start:
	./scripts/start-local-services.sh

cluster:
	./scripts/create-kind-cluster.sh

platform:
	./scripts/install-platform.sh

policies:
	./scripts/install-kyverno-policies.sh

root-app:
	./scripts/install-root-application.sh

verify:
	./scripts/verify-platform.sh

port-forwards:
	./scripts/port-forwards.sh

admission-tests:
	./tests/run-admission-tests.sh

clean:
	./scripts/cleanup.sh
