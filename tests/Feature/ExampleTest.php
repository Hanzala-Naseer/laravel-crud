<?php

it('redirects the home page to the tasks page', function () {
    $response = $this->get('/');

    $response->assertRedirect(route('tasks.index'));
});
