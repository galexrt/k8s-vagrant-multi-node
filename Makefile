up:
	vagrant up \
	    --parallel

stop:
	vagrant halt -f

clean:
	vagrant halt -f
	vagrant destroy -f

.PHONY: up clean
